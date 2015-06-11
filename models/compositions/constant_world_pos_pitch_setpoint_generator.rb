require 'rock_auv/models/services/controller'
require 'rock_auv/models/compositions/constant_setpoint_generator'

module RockAUV
    module Compositions
        ConstantWorldPosPitchSetpointGenerator = ConstantSetpointGenerator.for { WorldPos(:pitch) }
    end
end
