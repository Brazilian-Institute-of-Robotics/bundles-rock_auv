require 'rock_auv'

module RockAUV
    # Set of controllers to control a vehicle that is naturally stable in pitch
    # and roll.
    #
    # I.e. for this vehicle the aligned frame and body frames are identical.
    # Conversely, these controllers require only heading and depth measurements.
    #
    # They are exposed in the {Profiles::StablePitchRoll} profile
    #
    # The general structure of the control chain(s) are:
    #
    #   world_pos2aligned_pos using WorldToAligned converter
    #   aligned_pos2aligned_vel using a PIDController
    #   aligned_vel2body_effort using a PIDController
    #   and finally body_effort2body_thrust using an AccelerationController
    #
    # See {StablePitchRoll::RULES} for more details
    module StablePitchRoll
        extend Logger::Hierarchy
        extend Logger::Forward
    end
end

require "models/compositions/stable_pitch_roll/constant_world_pos_yaw_control"
require "models/compositions/stable_pitch_roll/constant_aligned_vel_yaw_control"
require "models/compositions/stable_pitch_roll/constant_world_pos_z_control"
require "models/compositions/stable_pitch_roll/constant_aligned_vel_z_control"
require "models/compositions/stable_pitch_roll/constant_world_pos_xy_control"

require "models/compositions/stable_pitch_roll/constant_aligned_vel_x_control"

require "models/compositions/stable_pitch_roll/constant_aligned_vel_y_control"

require "models/compositions/stable_pitch_roll/hover"
