require 'rock_auv/models/compositions/control_cascade'

module RockAUV
    module Compositions
        module StablePitchRoll
            RULES = [
                Control::Rule.new('world_pos2aligned_pos', [:world,:pos], [:aligned,:pos],
                                  Hash[Services::Control::Axis.new(:x,:y) => Services::Control::Axis.new(:x,:y)],
                                  OroGen::AuvControl::WorldToAligned),
                Control::Rule.new('aligned_pos2aligned_vel', [:aligned,:pos], [:aligned,:vel],
                                  Hash[Services::Control::Axis.new(:x,:y) => Services::Control::Axis.new(:x,:y)],
                                  OroGen::AuvControl::PIDController),
                Control::Rule.new('aligned_vel2body_effort', [:aligned,:vel], [:body,:effort],
                                  Hash[Services::Control::Axis.new(:x,:y) => Services::Control::Axis.new(:x,:y)],
                                  OroGen::AuvControl::PIDController),
                *Control::Generator::DEFAULT_THRUSTER_CONTROL_RULES]
        end
    end
end
