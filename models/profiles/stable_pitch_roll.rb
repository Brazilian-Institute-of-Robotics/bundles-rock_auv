require 'rock_auv/models/compositions/stable_pitch_roll'

module RockAUV
    module Profiles
        # Control of an AUV, assuming that pitch and roll are always zero
        #
        # This basically makes the aligned and body frames identical
        profile "StablePitchRoll" do
            # The system's thrusters
            tag 'thrusters', Rock::Services::JointsOpenLoopControlledSystem
            # Pure Z readings
            tag 'z_samples', Rock::Services::ZProvider
            # Attitude
            tag 'orientation_samples', Rock::Services::Orientation
            # Position
            tag 'xy_samples', Rock::Services::Position

            define 'goto_xy', Compositions::StablePitchRoll::ConstantWorldPosXYControl.
                use(thrusters_tag, xy_samples_tag, orientation_samples_tag)
            define 'constant_z', Compositions::StablePitchRoll::ConstantWorldPosZControl.
                use(thrusters_tag, z_samples_tag)
            define 'constant_yaw', Compositions::StablePitchRoll::ConstantWorldPosYawControl.
                use(thrusters_tag, orientation_samples_tag)
            define 'hover', Compositions::StablePitchRoll::Hover.
                use(thrusters_tag, xy_samples_tag, orientation_samples_tag)

            define 'constant_forward_velocity', Compositions::StablePitchRoll::ConstantAlignedVelXControl.
                use(thrusters_tag, xy_samples_tag)
            define 'constant_left_velocity', Compositions::StablePitchRoll::ConstantAlignedVelYControl.
                use(thrusters_tag, xy_samples_tag)
            define 'constant_z_velocity', Compositions::StablePitchRoll::ConstantAlignedVelZControl.
                use(thrusters_tag, z_samples_tag)
            define 'constant_yaw_velocity', Compositions::StablePitchRoll::ConstantAlignedVelYawControl.
                use(thrusters_tag, orientation_samples_tag)
        end
    end
end

