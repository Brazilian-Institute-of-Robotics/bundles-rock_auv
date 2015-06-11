require 'rock_auv/models/compositions/direct_control_rules'
require 'rock_auv/models/compositions/constant_world_pos_pitch_setpoint_generator'
require 'rock/models/services/orientation'

module RockAUV
    module Compositions
        # Composition that provides a direct control of Pitch, assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        class DirectPitchControl < Compositions::Control::Generator.new(DIRECT_CONTROL_RULES).create(world_pos_pitch: ConstantWorldPosPitchSetpointGenerator)
            argument :pitch

            add Rock::Services::Orientation, as: 'orientation_samples'
            orientation_samples_child.connect_to world_pos2body_effort_child

            overload 'world_pos_pitch', world_pos_pitch_child.
                with_arguments(setpoint: from(:parent_task).pitch)
        end
    end
end
