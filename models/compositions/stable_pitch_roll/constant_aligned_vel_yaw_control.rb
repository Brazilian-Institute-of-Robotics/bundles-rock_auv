require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/aligned_vel_yaw'
require 'rock/models/services/orientation'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantAlignedVelYawControl < Compositions::Control::Generator.new(RULES).create(aligned_vel_yaw: ConstantSetpointGenerators::AlignedVelYaw)
                argument :setpoint

                add Rock::Services::Orientation, as: 'orientation_samples'
                orientation_samples_child.connect_to aligned_vel2body_effort_child

                overload 'aligned_vel_yaw', aligned_vel_yaw_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
