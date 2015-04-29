import_types_from 'auv_control'

require 'rock_auv/models/services/control/element'
require 'rock/models/services/controller'
require 'rock/models/services/joints_control_loop'

module RockAUV
    module Services
        Controller = Control::Element.new_submodel do
            provides Rock::Services::Controller
        end

        WorldPosController = Control::WorldPos.new_submodel do
            provides Controller
            output_port 'cmd_out_world_pos', '/base/LinearAngular6DCommand'
        end
        WorldVelController = Control::WorldVel.new_submodel do
            provides Controller
            output_port 'cmd_out_world_vel', '/base/LinearAngular6DCommand'
        end
        AlignedPosController = Control::AlignedPos.new_submodel do
            provides Controller
            output_port 'cmd_out_aligned_pos', '/base/LinearAngular6DCommand'
        end
        AlignedVelController = Control::AlignedVel.new_submodel do
            provides Controller
            output_port 'cmd_out_aligned_vel', '/base/LinearAngular6DCommand'
        end
        AlignedEffortController = Control::AlignedEffort.new_submodel do
            provides Controller
            output_port 'cmd_out_aligned_effort', '/base/LinearAngular6DCommand'
        end
        BodyPosController = Control::BodyPos.new_submodel do
            provides Controller
            output_port 'cmd_out_body_pos', '/base/LinearAngular6DCommand'
        end
        BodyVelController = Control::BodyVel.new_submodel do
            provides Controller
            output_port 'cmd_out_body_vel', '/base/LinearAngular6DCommand'
        end
        BodyEffortController = Control::BodyEffort.new_submodel do
            provides Controller
            output_port 'cmd_out_body_effort', '/base/LinearAngular6DCommand'
        end
        data_service_type 'BodyThrustController' do
            output_port 'cmd_out_body_thrust', '/base/samples/Joints'
            provides Rock::Services::JointsOpenLoopController,
                'command_out' => 'cmd_out_body_thrust'
        end

        module Controller
            REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS = Hash[
                world: Hash[
                    pos: WorldPosController,
                    vel: WorldVelController],
                aligned: Hash[
                    pos: AlignedPosController,
                    vel: AlignedVelController,
                    effort: AlignedEffortController],
                body: Hash[
                    pos: BodyPosController,
                    vel: BodyVelController,
                    effort: BodyEffortController,
                    thrust: BodyThrustController]]

            # Returns the data used to represent a controller within a control domain
            #
            # @example The domain would usually be built by providing a block, such as
            #   RockAUV::Services::Controller.for do
            #      AlignedPos(:x, :y)
            #   end
            #
            # @see Control::DSL
            #
            def self.for(domains = nil, &block)
                Control::Element.for(self, domains, REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS, &block)
            end
        end
    end
end
