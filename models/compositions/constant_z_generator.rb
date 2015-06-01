require 'rock/models/compositions/constant_generator'
require 'rock_auv/models/services/controller'

import_types_from 'auv_control'

module RockAUV
    module Compositions
        class ConstantZGenerator < Rock::Compositions::ConstantGenerator.for('/base/LinearAngular6DCommand')
            provides Services::Controller.for { BodyPos(:z) }, as: 'z_producer'

            argument :z

            def z=(value)
                arguments[:z] = value
                cmd = Types.base.LinearAngular6DCommand.new(
                    time: Time.at(0),
                    linear: Eigen::Vector3.new(Base.unset, Base.unset, z),
                    angular: Eigen::Vector3.new(Base.unset, Base.unset, Base.unset))
                self.values = Hash['out' => cmd]
            end

            def values
                v = super().dup
                v['out'] = v['out'].dup
                v['out'].time = Time.now
                v
            end
        end
    end
end