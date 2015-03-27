require 'models/services/controller'
require 'models/services/controlled_system'

class OroGen::AuvControl::Base
    Hash['in' => RockAUV::Services::ControlledSystem::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS, 'out' => RockAUV::Services::Controller::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS].each do |prefix, srv_sets|
        srv_sets.each do |reference, quantities|
            quantities.each do |quantity, srv|
                dynamic_service srv, :as => "#{prefix}_#{reference}_#{quantity}" do
                    provides srv, :as => name, "cmd_in_#{reference}_#{quantity}" => "cmd_in_#{name}"
                end
            end
        end
    end
end

