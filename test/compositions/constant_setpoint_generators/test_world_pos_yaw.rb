require 'models/compositions/constant_setpoint_generators/world_pos_yaw'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe WorldPosYaw do
                ConstantSetpointGenerators.setup_common_test(self,
                    10,
                    :angular, :z, 10)
                ConstantSetpointGenerators.setup_common_test(self,
                    Hash[yaw: 10],
                    :angular, :z, 10)
            end
        end
    end
end
