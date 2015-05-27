require 'models/services/controller'
require 'models/services/controlled_system'

class OroGen::AuvControl::Base
    Hash['in' => RockAUV::Services::ControlledSystem::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS, 'out' => RockAUV::Services::Controller::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS].each do |prefix, srv_sets|
        srv_sets.each do |reference, quantities|
            quantities.each do |quantity, srv|
                dynamic_service srv, as: "#{prefix}_#{reference}_#{quantity}" do
                    actual_port_name =
                        if prefix == 'in'
                            "cmd_in_#{name}"
                        else
                            "cmd_out"
                        end

                    provides options[:control_domain_srv], as: name, "cmd_#{prefix}_#{reference}_#{quantity}" => actual_port_name
                end
            end
        end
    end

    AXIS_TO_EXPECTED_INPUTS = Hash[
        x: [:linear, 0],
        y: [:linear, 1],
        z: [:linear, 2],
        yaw: [:angular, 0],
        pitch: [:angular, 1],
        roll: [:angular, 2]
    ]

    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    def configure
        super

        expected_in = Types.auv_control.ExpectedInputs.new
        expected_in.zero!

        each_required_dynamic_service do |srv|
            # There is only one out service
            next if srv.model.dynamic_service.name =~ /^out/
            orocos_task.addCommandInput("in_#{srv.name}", 0)

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
        each_required_dynamic_service do |srv|
            if srv.model <= RockAUV::Services::ControlledSystem
                yield(srv)
            end
        end
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


class OroGen::AuvControl::PIDController
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
