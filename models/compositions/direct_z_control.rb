require 'rock_auv/models/services/z_controller'
require 'rock_auv/models/compositions/control_cascade'
require 'rock_auv/models/compositions/constant_z_generator'
require 'rock/models/services/z_provider'

module RockAUV
    module Compositions
        rules = [
            Control::Rule.new('body_pos2effort', [:body,:pos], [:body,:effort],
                              Hash[],
                              OroGen::AuvControl::PIDController),
            *Control::Generator::DEFAULT_THRUSTER_CONTROL_RULES]

        # Composition that provides a direct control of Z, assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        class DirectZControl < Compositions::Control::Generator.new(rules).create(z: ConstantZGenerator)
            argument :z

            add Rock::Services::ZProvider, as: 'z_samples'
            z_samples_child.connect_to body_pos2effort_child

            overload 'z', z_child.
                with_arguments(z: from(:parent_task).z)
        end
    end
end
