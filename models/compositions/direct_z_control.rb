require 'rock_auv/models/compositions/direct_control_rules'
require 'rock_auv/models/compositions/constant_world_pos_z_setpoint_generator'
require 'rock/models/services/z_provider'

module RockAUV
    module Compositions
        # Composition that provides a direct control of Z, assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        class DirectZControl < Compositions::Control::Generator.new(DIRECT_CONTROL_RULES).create(setpoint: ConstantWorldPosZSetpointGenerator)
            argument :z

            add Rock::Services::ZProvider, as: 'z_samples'
            z_samples_child.connect_to world_pos2body_effort_child

            overload 'setpoint', setpoint_child.
                with_arguments(setpoint: from(:parent_task).z)
        end
    end
end
