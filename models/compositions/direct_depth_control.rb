require 'rock/models/compositions/constant_generator'
require 'rock_auv/models/services/depth_controller'
require 'rock_auv/models/compositions/control_cascade'

module RockAUV
    module Compositions
        # Composition that provides a direct control of depth, assuming that the
        # system is naturally stable in pitch/roll
        #
        # This is mostly meant to be used during calibration
        binding.pry
        depth_generator = Rock::Compositions::ConstantGenerator.for(Types.base.LinearAngular6DCommand)
        depth_generator.provides Services::Controller.for { BodyPos(:z) }, as: 'depth_producer'

        rules = [
            Control::Rule.new('body_pos2effort', [:body,:pos], [:body,:effort],
                              Hash[],
                              AuvControl::PIDController),
            *Control::Generator::DEFAULT_THRUSTER_CONTROL_RULES]

        class DirectDepthControl < Compositions::Control::Generator.new(rules).create(depth: depth_generator)

        end
    end
end
