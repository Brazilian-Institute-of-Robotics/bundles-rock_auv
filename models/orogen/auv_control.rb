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
end

