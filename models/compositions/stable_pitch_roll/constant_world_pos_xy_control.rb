require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/constant_setpoint_generators/world_pos_xy'
require 'rock/models/services/position'

module RockAUV
    module Compositions
        module StablePitchRoll
            class ConstantWorldPosXYControl < Compositions::Control::Generator.new(RULES).create(world_pos_xy: ConstantSetpointGenerators::WorldPosXY)
                argument :setpoint

                add Rock::Services::Position, as: 'xy_samples'
                xy_samples_child.connect_to aligned_vel2body_effort_child

                overload 'world_pos_xy', world_pos_xy_child.
                    with_arguments(setpoint: from(:parent_task).setpoint)
            end
        end
    end
end
