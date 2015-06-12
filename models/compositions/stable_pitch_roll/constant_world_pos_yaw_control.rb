require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/world_pos_yaw'
require 'rock/models/services/orientation'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantWorldPosYawControl < Compositions::Control::Generator.new(RULES).create(world_pos_yaw: ConstantSetpointGenerators::WorldPosYaw)
                argument :setpoint

                add Rock::Services::Orientation, as: 'orientation_samples'
                orientation_samples_child.connect_to world_pos2aligned_pos_child
                orientation_samples_child.connect_to aligned_pos2aligned_vel_child
                orientation_samples_child.connect_to aligned_vel2body_effort_child

                overload 'world_pos_yaw', world_pos_yaw_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
