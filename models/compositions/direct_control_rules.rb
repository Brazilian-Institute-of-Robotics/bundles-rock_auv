require 'rock_auv/models/compositions/control_cascade'

module RockAUV
    module Compositions
        DIRECT_CONTROL_RULES = [
            Control::Rule.new('world_pos2body_effort', [:world,:pos], [:body,:effort],
                              Hash[],
                              OroGen::AuvControl::PIDController),
            *Control::Generator::DEFAULT_THRUSTER_CONTROL_RULES]
    end
end
