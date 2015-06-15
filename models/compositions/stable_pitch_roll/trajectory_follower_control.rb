require 'rock_auv/models/compositions/stable_pitch_roll/rules'
require 'rock_auv/models/compositions/trajectory_follower'

module RockAUV
    module Compositions
        module StablePitchRoll
            cascade = Compositions::Control::Generator.new(RULES).
                create(trajectory: TrajectoryFollower)

            class TrajectoryFollowerControl < cascade
                # A Array<SISL::Spline3> object that will be executed. If not
                # provided, the trajectory input port must be connected
                argument :trajectory, default: nil

                add Rock::Services::Pose, as: 'pose'

                pose_child.connect_to aligned_vel2body_effort_child

                overload 'trajectory', trajectory_child.
                    with_arguments(trajectory: from(:parent_task).trajectory).
                    use('pose' => pose_child)

                export trajectory_child.trajectory_port
                provides Rock::Services::TrajectoryExecution, as: 'trajectory_execution'
            end
        end
    end
end
