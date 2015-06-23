require 'models/compositions/constant_setpoint_generators/aligned_vel_x'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe AlignedVelX do
                ConstantSetpointGenerators.setup_common_test(self,
                    10,
                    :linear, :x, 10)
                ConstantSetpointGenerators.setup_common_test(self,
                    Hash[x: 10],
                    :linear, :x, 10)
            end
        end
    end
end
