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
                if !options[:port_name]
                    raise ArgumentError, "instanciating the in_#{reference}_#{quantity} dynamic service requires a port_name: option with the name of the port that should be created"
                elsif !options[:control_domain_srv]
                    raise ArgumentError, "instanciating the in_#{reference}_#{quantity} dynamic service requires a control_domain_srv: option with the service model that should be actually instanciated"
                end
                provides options[:control_domain_srv], as: name,
                    "cmd_in_#{reference}_#{quantity}" =>  "cmd_in_#{options[:port_name]}"
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

    # Stub the operations. Applied to the underlying
    # Orocos::RubyTasks::StubTaskContext in non-live test mode
    stub do
        def addCommandInput(name, *args)
            create_input_port "cmd_#{name}", '/base/LinearAngular6DCommand'
        end
    end

    # The expected set of inputs
    #
    # @return [Types.auv_control.ExpectedInputs]
    attr_reader :expected_inputs

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
    def self.add_input(domain = nil, as: nil, port_name: as, &domain_def)
        model = ensure_model_is_specialized
        controlled_system_srv = RockAUV::Services::ControlledSystem.for(domain, &domain_def)
        r, q, _ = controlled_system_srv.domain.simple_domain
        model.require_dynamic_service(
            "in_#{r}_#{q}", as: as,
            control_domain_srv: controlled_system_srv,
            port_name: port_name)
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
            add_ports_for_controlled_system_service(srv)
        end
    end

    # Hook called when a new dynamic service is created on this task
    #
    # It calls addCommandInput on the new service, expected_inputs gets updated
    # by {#added_input_port_connection} and {#removed_input_port_connection}
    def added_dynamic_service(srv)
        super

        if setup? && srv.model.fullfills?(RockAUV::Services::ControlledSystem)
            add_ports_for_controlled_system_service(srv)
        end
        srv
    end

    def add_ports_for_controlled_system_service(srv)
        srv.each_input_port do |port|
            port_name = port.to_component_port.name
            cmd_name  = port_name.gsub("cmd_", '')
            if !orocos_task.has_port?(port_name)
                orocos_task.addCommandInput(cmd_name, 0)
            end
        end
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

    def compute_expected_inputs
        expected_in = Types.auv_control.ExpectedInputs.new
        expected_in.zero!
        _, _, axis = full_input_domain.simple_domain
        axis.each do |axis_name|
            field, idx = AXIS_TO_EXPECTED_INPUTS[axis_name]
            expected_in.send(field)[idx] = true
        end
        expected_in
    end

    def update_expected_inputs
        computed = compute_expected_inputs

        @expected_inputs = computed
        if orocos_task
            orocos_task.expected_inputs = computed
        end
        each_concrete_output_connection do |_, _, sink_task, _|
            if sink_task.respond_to?(:update_expected_inputs)
                sink_task.update_expected_inputs
            end
        end
        computed
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
        ref, _, _ = full_input_domain.simple_domain
        ref == :world
    end

    def self.position_control?
        _, dom, _ = full_input_domain.simple_domain
        dom == :pos
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

    def each_input_domain
        return enum_for(__method__) if !block_given?

        all_cmd_in_ports = Hash.new { |h, k| h[k] = Array.new }
        each_dynamic_controlled_system_service do |srv|
            srv.each_input_port do |p|
                cmd_in_port = p.to_component_port
                all_cmd_in_ports[cmd_in_port.name] << srv
            end
        end

        result = RockAUV::Services::Control::Domain.new
        each_concrete_input_connection do |source_task, source_port_name, sink_port_name, _|
            next if !(services = all_cmd_in_ports[sink_port_name])

            services.each do |srv|
                # 'srv' is the data service bound to this instance
                # srv.model is the data service bound to this instance's model
                # srv.model.model is the data service model itself
                domain = srv.model.model.domain
                if source_task.respond_to?(:full_output_domain)
                    domain = source_task.full_output_domain & domain
                end
                yield(find_port(sink_port_name), domain, srv)
            end
        end
    end

    def full_input_domain
        each_input_domain.inject(RockAUV::Services::Control::Domain.new) do |d, (_, in_d, _)|
            d | in_d
        end
    end

    def full_output_domain
        in_domain = full_input_domain
        output_domain = self.model.full_output_domain
        if output_domain.empty?
            raise ArgumentError, "output domain for #{self} has not been marked with a data service"
        end
        r, q, _ = output_domain.simple_domain
        _, _, a = in_domain.simple_domain
        RockAUV::Services::Control::Domain.new(r, q, a)
    end

    # Tests whether two controllers can be merged
    #
    # In addition to the normal Syskit checks, it checks that the controller's
    # input domains are compatible
    def can_merge?(other_task)
        return if !super

        this_domain = full_input_domain
        other_task.each_input_domain.all? do |in_port, in_domain, in_srv|
            find_data_service(in_srv.name) ||
                !this_domain.intersects_with?(in_domain)
        end
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


