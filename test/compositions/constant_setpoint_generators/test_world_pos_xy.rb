require 'models/compositions/constant_setpoint_generators/world_pos_xy'
require_relative 'helpers'

module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            describe WorldPosXY do
                ConstantSetpointGenerators.setup_common_test(self,
                    Hash[x: 10, y: 20],
                    :linear, :x, 10,
                    :linear, :y, 20)
            end
        end
    end
end
