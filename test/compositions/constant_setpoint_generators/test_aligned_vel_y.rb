require 'models/compositions/constant_setpoint_generators/aligned_vel_y'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe AlignedVelY do
                ConstantSetpointGenerators.setup_common_test(self,
                    10,
                    :linear, :y, 10)
                ConstantSetpointGenerators.setup_common_test(self,
                    Hash[y: 10],
                    :linear, :y, 10)
            end
        end
    end
end
