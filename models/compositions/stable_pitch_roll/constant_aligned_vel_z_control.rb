require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/aligned_vel_z'
require 'rock/models/services/z_provider'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantAlignedVelZControl < Compositions::Control::Generator.new(RULES).create(aligned_vel_z: ConstantSetpointGenerators::AlignedVelZ)
                argument :setpoint

                add Rock::Services::ZProvider, as: 'z_samples'
                z_samples_child.connect_to aligned_vel2body_effort_child

                overload 'aligned_vel_z', aligned_vel_z_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
