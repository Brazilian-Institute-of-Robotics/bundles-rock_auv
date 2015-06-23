require 'models/compositions/constant_setpoint_generators/aligned_vel_z'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe AlignedVelZ do
                ConstantSetpointGenerators.setup_common_test(self,
                    10,
                    :linear, :z, 10)
                ConstantSetpointGenerators.setup_common_test(self,
                    Hash[z: 10],
                    :linear, :z, 10)
            end
        end
    end
end
