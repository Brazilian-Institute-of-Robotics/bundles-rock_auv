require 'rock_auv/models/compositions/direct_control_rules'
require 'rock_auv/models/compositions/constant_world_pos_yaw_setpoint_generator'
require 'rock/models/services/orientation'

module RockAUV
    module Compositions
        # Composition that provides a direct control of Yaw (heading), assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        class DirectYawControl < Compositions::Control::Generator.new(DIRECT_CONTROL_RULES).create(setpoint: ConstantWorldPosYawSetpointGenerator)
            argument :yaw

            add Rock::Services::Orientation, as: 'orientation_samples'
            orientation_samples_child.connect_to world_pos2body_effort_child

            overload 'setpoint', setpoint_child.
                with_arguments(setpoint: from(:parent_task).yaw)
        end
    end
end
