require 'rock_auv/models/compositions/control/generator'

module RockAUV
    module Compositions
        # Root model for the control cascades based on auv_control 
        #
        # It also provides automatic (and typechecked) generation of a control
        # cascade for a certain set of producers. One would call 
        #

        class ControlCascade < Syskit::Composition
            # Creates a composition, submodel of ControlCascade, in which the
            # following producers are wired up to the acceleration controller
            #
            # It can be used directly in profiles, or (at your convenience),
            # by subclassing it
            def self.for(producers, rules: Control::Generator::DEFAULT_RULES)
                Control::Generator.new(rules).create(producers)
            end

            add Rock::Services::JointsOpenLoopControlledSystem, as: 'thrusters'
        end
    end
end

