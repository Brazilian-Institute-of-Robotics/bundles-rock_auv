require 'rock_auv/models/services/controller'
require 'rock_auv/models/compositions/constant_setpoint_generator'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            AlignedVelZ = ConstantSetpointGenerator.for { AlignedVel(:z) }
        end
    end
end
