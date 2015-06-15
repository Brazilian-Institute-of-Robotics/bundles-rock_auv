require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/aligned_vel_y'
require 'rock/models/services/position'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantAlignedVelYControl < Compositions::Control::Generator.new(RULES).create(aligned_vel_y: ConstantSetpointGenerators::AlignedVelY)
                argument :setpoint

                add Rock::Services::Position, as: 'y_samples'
                y_samples_child.connect_to aligned_vel2body_effort_child

                overload 'aligned_vel_y', aligned_vel_y_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
