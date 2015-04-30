require 'rock_auv/models/services/depth_controller'
require 'rock_auv/models/compositions/control_cascade'
require 'rock_auv/models/compositions/constant_depth_generator'
require 'rock/models/services/z_provider'

module RockAUV
    module Compositions
        rules = [
            Control::Rule.new('body_pos2effort', [:body,:pos], [:body,:effort],
                              Hash[],
                              OroGen::AuvControl::PIDController),
            *Control::Generator::DEFAULT_THRUSTER_CONTROL_RULES]

        # Composition that provides a direct control of depth, assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        class DirectDepthControl < Compositions::Control::Generator.new(rules).create(depth: ConstantDepthGenerator)
            argument :depth

            add Rock::Services::ZProvider, as: 'depth_samples'
            depth_samples_child.connect_to body_pos2effort_child

            overload 'depth', depth_child.
                with_arguments(depth: from(:parent_task).depth)
        end
    end
end
