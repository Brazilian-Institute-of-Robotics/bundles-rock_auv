import_types_from 'auv_control'

require 'rock_auv/models/services/control/element'
require 'rock/models/services/controlled_system'

module RockAUV
    module Services
        ControlledSystem = Control::Element.new_submodel do
            provides Rock::Services::ControlledSystem
        end

        WorldPosControlledSystem  = Control::WorldPos.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in', '/base/LinearAngular6DCommand'
        end
        WorldVelControlledSystem  = Control::WorldVel.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in_world_vel', '/base/LinearAngular6DCommand'
        end
        AlignedPosControlledSystem  = Control::AlignedPos.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in_aligned_pos', '/base/LinearAngular6DCommand'
        end
        AlignedVelControlledSystem  = Control::AlignedVel.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in_aligned_vel', '/base/LinearAngular6DCommand'
        end
        AlignedEffortControlledSystem  = Control::AlignedEffort.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in_aligned_effort', '/base/LinearAngular6DCommand'
        end
        BodyEffortControlledSystem  = Control::BodyEffort.new_submodel do
            provides ControlledSystem
            input_port 'cmd_in_body_effort', '/base/LinearAngular6DCommand'
        end

        module ControlledSystem
            REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS = Hash[
                :world => Hash[
                    :pos => WorldPosControlledSystem,
                    :vel => WorldVelControlledSystem],
                :aligned => Hash[
                    :pos => AlignedPosControlledSystem,
                    :vel => AlignedVelControlledSystem,
                    :effort => AlignedEffortControlledSystem],
                :body => Hash[
                    :effort => BodyEffortControlledSystem]]

            def self.for(domains = nil, &block)
                Control::Element.for(domains, REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS, &block)
            end
        end
    end
end
