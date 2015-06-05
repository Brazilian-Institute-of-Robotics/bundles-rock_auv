require 'rock_auv/models/services/controller'
require 'rock_auv/models/compositions/constant_setpoint_generator'

module RockAUV
    module Compositions
        ConstantWorldPosYawSetpointGenerator = ConstantSetpointGenerator.for { WorldPos(:yaw) }
    end
end
