require 'models/services/controller'
require 'models/services/controlled_system'

# Generic handling of controller input/output typing
#
# Creating and Typing Inputs and Outputs
# --------------------------------------
# auv_control-based controllers are "typed" in which part of the control domain
# their input is expressed, and which part of the control domain their output
# is. One creates dynamic inputs with {.add_input} and types the controller's
# output with {.add_output}
#
# Input/Output Typing Using Dynamic Services
# ------------------------------------------
# Under the scene, the {.add_input} and {.add_output} helpers use dynamic
# services. One dynamic service for each reference/quantity pair has been
# declared on this task model, both on inputs and outputs.
#
# For instance, if one needs to instanciate an aligned-velocity input, he would
# use the 'in_aligned_velocity' service. The service would in turn create the
# "cmd_in_#{name}" port, where name is the name of the instanciated service (the
# argument to the 'as' option)
#
# On the output side, the goal is more to provide typing for the output (as all
# controllers only have one output). If the controller generates in the
# body-effort domain, one would instanciate a 'out_aligned_velocity' service.
# The service's output port would in turn be mapped to the task's cmd_out port.
#
# In both cases, the dynamic services expect a control_domain_srv option with
# the data service representing the full control domain (reference, quantity and
# axis).
#
# @example create an input in body-position-Z
#   domain_srv = RockAUV::Services::Control::Domain { BodyPosition(:z) }
#   task_model.require_dynamic_service 'in_body_position', as: 'depth',
#       control_domain_srv: domain_srv
class OroGen::AuvControl::Base
    RockAUV::Services::ControlledSystem::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS.each do |reference, quantities|
        quantities.each do |quantity, srv|
            dynamic_service srv, as: "in_#{reference}_#{quantity}", dynamic: true, remove_when_unused: false do
                actual_port_name = "cmd_in_#{name}"
                provides options[:control_domain_srv], as: name,
                    "cmd_in_#{reference}_#{quantity}" => actual_port_name
            end
        end
    end

    RockAUV::Services::Controller::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS.each do |reference, quantities|
        quantities.each do |quantity, srv|
            dynamic_service srv, as: "out_#{reference}_#{quantity}", dynamic: true, remove_when_unused: false do
                provides options[:control_domain_srv], as: name,
                    "cmd_out_#{reference}_#{quantity}" => "cmd_out"
            end
        end
    end

    AXIS_TO_EXPECTED_INPUTS = Hash[
        x: [:linear, 0],
        y: [:linear, 1],
        z: [:linear, 2],
        roll: [:angular, 0],
        pitch: [:angular, 1],
        yaw: [:angular, 2]
    ]

    # Adds a controller input within the given control domain
    #
    # It creates a new task port called 'cmd_in_#{as}'
    #
    # @param [RockAUV::Services::Domain,nil] domain the domain object. Can also
    #   be provided by a block which would be passed to
    #   {RockAUV::Services::ControlledSystem.for}
    # @param [String] as the service name. The created input port will be called
    #   "cmd_in_#{as}"
    # @return [Model<Component>] the component model that has the corresponding
    #   service. It might not be self.
    #
    # @example create world-pos-Z input called 'depth'
    #   model = PIDController.add_input(as: 'depth') { WorldPos(:z) }
    #
    # @see add_output
    def self.add_input(domain = nil, as: nil, &domain_def)
        model = ensure_model_is_specialized
        controlled_system_srv = RockAUV::Services::ControlledSystem.for(domain, &domain_def)
        r, q, _ = controlled_system_srv.domain.simple_domain
        model.require_dynamic_service(
            "in_#{r}_#{q}", as: as,
            control_domain_srv: controlled_system_srv)
        model
    end

    # Defines all or part of the output domain
    #
    # Unlike with {.add_input}, no dynamic ports get created. All controllers
    # have a single cmd_out output port.
    #
    # @param [RockAUV::Services::Domain,nil] domain the domain object. Can also
    #   be provided by a block which would be passed to
    #   {RockAUV::Services::Controller.for}
    # @param [String] as the service name
    # @return [Model<Component>] the component model that has the corresponding
    #   service. It might not be self.
    #
    # @example declare that the controller outputs in body-effort-yaw
    #   model = PIDController.add_output(as: 'yaw') { BodyEffort(:yaw) }
    #
    # @see .add_input
    def self.add_output(domain = nil, as: nil, &domain_def)
        model = ensure_model_is_specialized
        controller_srv = RockAUV::Services::Controller.for(domain, &domain_def)
        r, q, _ = controller_srv.domain.simple_domain
        model.require_dynamic_service(
            "out_#{r}_#{q}", as: as,
            control_domain_srv: controller_srv)
        model
    end

    # Sets up the controller according to which services have been instanciated.
    #
    # It sets all the relevant configuration properties accordingly
    # (expected_inputs, ...)
    def configure
        super
        update_expected_inputs
        each_dynamic_controlled_system_service do |srv|
            orocos_task.addCommandInput("in_#{srv.name}", 0)
        end
    end

    # Hook called when a new dynamic service is created on an already configured
    # task
    #
    # It calls addCommandInput on the new service, expected_inputs gets updated
    # by {#added_input_port_connection} and {#removed_input_port_connection}
    def added_dynamic_service(srv)
        super

        update_expected_inputs

        if setup? && srv.model.fullfills?(RockAUV::Services::ControlledSystem)
            orocos_task.addCommandInput("in_#{srv.name}", 0)
        end
        srv
    end

    # Hook called by Syskit at runtime when connections have been added
    #
    # It is called just after adding the connection
    #
    # @param [Syskit::Port] source_port
    # @param [Syskit::Port] sink_port
    # @param [Hash] policy
    def added_input_port_connection(source_port, sink_port, policy)
        super
        update_expected_inputs
    end

    # Hook called by Syskit at runtime when connections have been removed
    #
    # It is called just after removing the connection
    #
    # @param [Orocos::TaskContext] source_task
    # @param [String] source_port
    # @param [String] sink_port
    def removed_input_port_connection(source_task, source_port, sink_port)
        super
        update_expected_inputs
    end

    # Enumerates every instanciated dynamic input service
    def each_dynamic_controlled_system_service
        each_required_dynamic_service do |srv|
            # There is only one out service
            next if !srv.model.fullfills?(RockAUV::Services::ControlledSystem)

            yield(srv)
        end
    end

    def update_expected_inputs
        expected_in = Types.auv_control.ExpectedInputs.new
        expected_in.zero!
        each_dynamic_controlled_system_service do |srv|
            # Do not consider services that are not connected to anything (the
            # task implementation silently ignores them as well)
            next if !srv.each_input_port.any? { |p| p.connected? }

            # 'srv' is the data service bound to this instance
            # srv.model is the data service bound to this instance's model
            # srv.model.model is the data service model itself
            srv.model.model.domain.each do |_, dom, axis|
                axis.each do |axis_name|
                    field, idx = AXIS_TO_EXPECTED_INPUTS[axis_name]
                    expected_in.send(field)[idx] = true
                end
            end
        end
        orocos_task.expected_inputs = expected_in
    end

    def self.each_dynamic_controlled_system_service
        return enum_for(__method__) if !block_given?
        each_required_dynamic_service do |srv|
            if srv.model <= RockAUV::Services::ControlledSystem
                yield(srv)
            end
        end
    end

    def self.each_dynamic_controller_service
        return enum_for(__method__) if !block_given?
        each_required_dynamic_service do |srv|
            if srv.model <= RockAUV::Services::Controller
                yield(srv)
            end
        end
    end

    def self.world_frame?
        result = nil
        each_dynamic_controlled_system_service do |srv|
            srv.model.domain.each do |ref, _, _|
                if result.nil?
                    result = (ref == :world)
                else
                    if (ref == :world) != result
                        services = each_required_dynamic_service.map { |srv| "#{srv.name}(#{srv.model})" }.join(", ")
                        raise ArgumentError, "controller is configured to accept both world and other references: #{services}"
                    end
                end
            end
        end
        return !!result
    end

    def self.position_control?
        position_control = nil
        each_dynamic_controlled_system_service do |srv|
            srv.model.domain.each do |_, dom, _|
                if position_control.nil?
                    position_control = (dom == :pos)
                else
                    if (dom == :pos) != position_control
                        services = each_required_dynamic_service.map { |srv| "#{srv.name}(#{srv.model})" }.join(", ")
                        raise ArgumentError, "controller is configured to accept both position and velocity/effort: #{services}"
                    end
                end
            end
        end
        return !!position_control
    end
end

class OroGen::AuvControl::BasePIDController
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::PIDController
    # Sets up the controller according to which services have been instanciated.
    #
    # It sets all the relevant configuration properties, that are not already
    # set by {ControllerBase#configure} (world_frame, position_control, ...)
    def configure
        super
        orocos_task.world_frame = self.model.world_frame?
        orocos_task.position_control = self.model.position_control?
    end

    def self.full_input_domain
        each_dynamic_controlled_system_service.
            inject(RockAUV::Services::Control::Domain.new) do |d, srv|
                d | srv.model.domain
            end
    end

    def self.full_output_domain
        each_dynamic_controller_service.
            inject(RockAUV::Services::Control::Domain.new) do |d, srv|
                d | srv.model.domain
            end
    end

    # Tests whether two controllers can be merged
    #
    # In addition to the normal Syskit checks, it checks that the controller's
    # input domains are compatible
    def can_merge?(other_task)
        super && model.can_merge?(other_task.model)
    end

    # Tests whether a +model+ can be merged into +self+
    #
    # It verifies that the merge is valid w.r.t. the controlled domains
    def self.can_merge?(model)
        return if !super

        # Check for services in other_task that are not in self and verify that
        # adding them to self would not cause a conflict
        #
        # Note that the superclass' can_merge? implementation already tests that
        # services that have the same name are from the same type, so we only
        # have to test for the service presence on self
        this_domain  = full_input_domain
        model.each_dynamic_controlled_system_service.all? do |srv|
            find_data_service(srv.name) ||
                !this_domain.conflicts_with?(srv.model.domain)
        end
    end
end

class OroGen::AuvControl::WorldToAligned
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    def configure
        super
        orocos_task.position_control = self.model.position_control?
    end
end

class OroGen::AuvControl::AlignedToBody
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::AccelerationController
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::ConstantCommand
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::ConstantCommandGroundFollower
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::WaypointNavigator
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::MotionCommand2DConverter
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end

class OroGen::AuvControl::OptimalHeadingController
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
end


