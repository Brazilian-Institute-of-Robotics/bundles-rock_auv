require 'rock_auv/models/services/control/domain'

module RockAUV
    module Services
        module Control
            # @api private
            #
            # Evaluation context for the blocks given to {Services::Domain.for}
            #
            # This is a helper for {Controller.for} and
            # {ControlledSystem.for}
            class DSL < BasicObject
                # @!macro common
                #   The axis names are one of :x, :y, :z, :roll, :pitch, :yaw
                #
                #   @raise InvalidAxis if an invalid axis name is given
                #   @return [Domain]

                # Creates a {Domain} object applying on world and position for
                # the given axis
                #
                # @!macro common
                def WorldPos(*axis)
                    Domain.new(:world, :pos, Axis.new(*axis))
                end

                # Creates a {Domain} object applying on world and velocity for
                # the given axis
                #
                # @!macro common
                def WorldVel(*axis)
                    Domain.new(:world, :vel, Axis.new(*axis))
                end

                # Creates a {Domain} object applying on aligned and position for
                # the given axis
                #
                # @!macro common
                def AlignedPos(*axis)
                    Domain.new(:aligned, :pos, Axis.new(*axis))
                end

                # Creates a {Domain} object applying on aligned and velocity for
                # the given axis
                #
                # @!macro common
                def AlignedVel(*axis)
                    Domain.new(:aligned, :vel, Axis.new(*axis))
                end

                # Creates a {Domain} object applying on aligned and effort for
                # the given axis
                #
                # @!macro common
                def AlignedEffort(*axis)
                    Domain.new(:aligned, :effort, Axis.new(*axis))
                end

                # Creates a {Domain} object applying on body and effortfor
                # the given axis
                #
                # @!macro common
                def BodyEffort(*axis)
                    Domain.new(:body, :effort, Axis.new(*axis))
                end

                # Create a domain object from the block passed as argument.
                def self.eval(&block)
                    new.instance_eval(&block)
                end
            end
        end
    end
end
