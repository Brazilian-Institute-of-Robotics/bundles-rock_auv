require 'rock/models/services/orientation'
require 'models/compositions/direct_z_control'
require 'models/compositions/direct_yaw_control'
require 'models/compositions/direct_pitch_control'

module RockAUV
    module Profiles
        profile "AUVControlCalibration" do
            # The system's thrusters
            tag 'thrusters', Rock::Services::JointsOpenLoopControlledSystem
            # Pure Z readings
            tag 'z_samples', Rock::Services::ZProvider
            # Attitude
            tag 'orientation_samples', Rock::Services::Orientation

            # Direct PID control of depth thrusters. Uses only a depth sensor
            #
            # This is the very first controller you want to tune. It basically
            # assumes that the system is keeping horizontal (most AUVs will do
            # that naturally), and brings it to a certain depth.
            #
            # The goal here is to be able to be submerged so that we can tune
            # the other controllers -- as for instance pitch/roll control
            define 'direct_z_control', Compositions::DirectZControl.
                use(thrusters_tag, z_samples_tag)

            # Direct yaw control. Uses only a yaw sensor
            #
            # This would be the second controller you want to tune. It basically
            # assumes that the system is keeping horizontal (most AUVs will do
            # that naturally), and keeps its yaw constant
            define 'direct_yaw_control', Compositions::DirectYawControl.
                use(thrusters_tag, orientation_samples_tag)

            # Direct pitch control. Uses only a yaw sensor
            define 'direct_pitch_control', Compositions::DirectPitchControl.
                use(thrusters_tag, orientation_samples_tag)
        end
    end
end

