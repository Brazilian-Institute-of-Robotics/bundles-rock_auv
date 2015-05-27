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

        position_control = nil

        each_required_dynamic_service do |srv|
            # There is only one out service
            next if srv.model.dynamic_service.name =~ /^out/
            orocos_task.addCommandInput("in_#{srv.name}", 0)

            # 'srv' is the data service bound to this instance
            # srv.model is the data service bound to this instance's model
            # srv.model.model is the data service model itself
            srv.model.model.domain.each do |_, dom, axis|
                if position_control.nil?
                    position_control = (dom == :pos)
                else
                    if (dom == :pos) != position_control
                        raise ArgumentError, "controller is configured to accept both position and velocity/effort"
                    end
                end

                axis.each do |axis_name|
                    field, idx = AXIS_TO_EXPECTED_INPUTS[axis_name]
                    expected_in.send(field)[idx] = true
                end
            end
        end
        orocos_task.position_control = !!position_control
        orocos_task.expected_inputs = expected_in
    end
end

