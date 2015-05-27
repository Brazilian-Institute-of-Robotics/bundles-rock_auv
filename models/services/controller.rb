import_types_from 'auv_control'

require 'rock_auv/models/services/control/element'
require 'rock/models/services/controller'
require 'rock/models/services/joints_control_loop'

module RockAUV
    module Services
        # Base service for components that generate commands
        data_service_type 'Controller', parent: Control::Element do
            provides Rock::Services::Controller
        end

        # Base type for controllers that generate positions in the world frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { WorldPos(:x, :yaw) }
        # ```
        data_service_type 'WorldPosController', parent: Control::WorldPos do
            provides Controller
            output_port 'cmd_out_world_pos', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate velocities in the world frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { WorldVel(:x, :yaw) }
        # ```
        data_service_type "WorldVelController", parent: Control::WorldVel do
            provides Controller
            output_port 'cmd_out_world_vel', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate positions in the aligned frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { AlignedPos(:x, :yaw) }
        # ```
        data_service_type "AlignedPosController", parent: Control::AlignedPos do
            provides Controller
            output_port 'cmd_out_aligned_pos', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate velocities in the aligned frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { AlignedVel(:x, :yaw) }
        # ```
        data_service_type "AlignedVelController", parent: Control::AlignedVel do
            provides Controller
            output_port 'cmd_out_aligned_vel', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate effort in the aligned frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { AlignedEffort(:x, :yaw) }
        # ```
        data_service_type 'AlignedEffortController', parent: Control::AlignedEffort do
            provides Controller
            output_port 'cmd_out_aligned_effort', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate positions in the body frame.
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { BodyPos(:x, :yaw) }
        # ```
        data_service_type "BodyPosController", parent: Control::BodyPos do
            provides Controller
            output_port 'cmd_out_body_pos', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate velocities in the body frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { BodyVel(:x, :yaw) }
        # ```
        data_service_type "BodyVelController", parent: Control::BodyVel do
            provides Controller
            output_port 'cmd_out_body_vel', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate effort in the body frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { BodyEffort(:x, :yaw) }
        # ```
        data_service_type "BodyEffortController", parent: Control::BodyEffort do
            provides Controller
            output_port 'cmd_out_body_effort', '/base/LinearAngular6DCommand'
        end

        # Base type for controllers that generate effort in the aligned frame
        #
        # Such a controller for x and yaw axis would be created with
        #
        # ```
        # RockAUV::Services::Controller.for { AlignedEffort(:x, :yaw) }
        # ```
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
