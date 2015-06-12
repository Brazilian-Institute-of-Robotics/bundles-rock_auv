require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/world_pos_z'
require 'rock/models/services/z_provider'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantWorldPosZControl < Compositions::Control::Generator.new(RULES).create(world_pos_z: ConstantSetpointGenerators::WorldPosZ)
                argument :setpoint

                add Rock::Services::ZProvider, as: 'z_samples'
                z_samples_child.connect_to world_pos2aligned_pos_child
                z_samples_child.connect_to aligned_pos2aligned_vel_child
                z_samples_child.connect_to aligned_vel2body_effort_child

                overload 'world_pos_z', world_pos_z_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
