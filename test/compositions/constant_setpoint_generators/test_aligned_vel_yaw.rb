require 'models/compositions/constant_setpoint_generators/aligned_vel_yaw'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe AlignedVelYaw do
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
