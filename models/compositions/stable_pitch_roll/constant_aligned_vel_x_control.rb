require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/aligned_vel_x'
require 'rock/models/services/position'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantAlignedVelXControl < Compositions::Control::Generator.new(RULES).create(aligned_vel_x: ConstantSetpointGenerators::AlignedVelX)
                argument :setpoint

                add Rock::Services::Position, as: 'x_samples'
                x_samples_child.connect_to aligned_vel2body_effort_child

                overload 'aligned_vel_x', aligned_vel_x_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
