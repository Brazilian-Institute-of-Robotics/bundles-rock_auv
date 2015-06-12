require 'rock_auv/models/services/controller'
require 'rock_auv/models/compositions/constant_setpoint_generator'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            WorldPosYaw = ConstantSetpointGenerator.for { WorldPos(:yaw) }
        end
    end
end
