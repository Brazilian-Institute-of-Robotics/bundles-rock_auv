require 'rock/models/compositions/constant_generator'
require 'rock_auv/models/services/controller'

import_types_from 'auv_control'

module RockAUV
    module Compositions
        class ConstantSetpointGenerator < Rock::Compositions::ConstantGenerator.for('/base/LinearAngular6DCommand')
            # The setpoint, as a hash from the controlled axes to the setpoint
            # values
            #
            # @example
            #   ConstantSetpointGenerator.new(setpoint: Hash[x: 10])
            #
            # @return [Hash]
            argument :setpoint

            AXIS_NAMES = Array[:x, :y, :z, :yaw, :pitch, :roll]

            def setpoint=(hash)
                expected_domain = model.domain_srv.model.domain
                _, _, axis = expected_domain.simple_domain

                if hash.kind_of?(Numeric)
                    axis_names = axis.each.to_a
                    if axis_names.size == 1
                        hash = Hash[axis_names.first => hash]
                    else
                        raise ArgumentError, "more than one axis expected, you must set the 'setpoint' argument to a hash"
                    end
                end

                (AXIS_NAMES - axis.each.to_a).each do |axis_name|
                    if hash.has_key?(axis_name) && !Base.unset?(hash[axis_name])
                        raise ArgumentError, "expected axis #{axis_name} to not be set in setpoint, but it is"
                    end
                end
                axis.each do |axis_name|
                    if !hash.has_key?(axis_name) || Base.unset?(hash[axis_name])
                        raise ArgumentError, "expected axis #{axis_name} to be set in setpoint, but it is not"
                    end
                end

                p = Types.base.LinearAngular6DCommand.new
                p.time = Time.at(0)
                values = AXIS_NAMES.map do |axis_name|
                    (hash[axis_name] || Base.unset)
                end
                p.linear  = Eigen::Vector3.new(*values[0, 3])
                p.angular = Eigen::Vector3.new(*values[3, 3])
                arguments[:setpoint] = hash.dup
                self.values = Hash[out: p]
            end

            def values
                cmd = super['out'].dup
                cmd.time = Time.now
                Hash['out' => cmd]
            end

            # @param (see Services::Controller.for)
            def self.for(domain = nil, &block)
                result = new_submodel
                srv_domain = Services::Controller.for(domain, &block)
                # Verify that the domain is simple
                srv_domain.domain.simple_domain
                result.provides srv_domain, as: 'domain'
                result
            end
        end
    end
end
