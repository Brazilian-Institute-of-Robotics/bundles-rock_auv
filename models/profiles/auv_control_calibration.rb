require 'models/compositions/direct_depth_control'

module RockAUV
    module Profiles
        profile "AUVControlCalibration" do
            # The system's thrusters
            tag 'thrusters', Rock::Services::JointsOpenLoopControlledSystem
            # Pure depth readings
            tag 'depth_samples', Rock::Services::ZProvider

            # Direct PID control of depth thrusters. Uses only a depth sensor
            #
            # This is the very first controller you want to tune. It basically
            # assumes that the system is keeping horizontal (most AUVs will do
            # that naturally), and brings it to a certain depth.
            #
            # The goal here is to be able to be submerged so that we can tune
            # the other controllers -- as for instance pitch/roll control
            define 'direct_depth_control', Compositions::DirectDepthControl.
                use(thrusters_tag, depth_samples_tag)
        end
    end
end
