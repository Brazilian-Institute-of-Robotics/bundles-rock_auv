require 'sisl/spline'
require 'eigen'
require 'rock/models/services/pose'
require 'rock_auv/models/compositions/stable_pitch_roll/trajectory_follower_control'

module RockAUV
    module Compositions
        module StablePitchRoll
            class GotoXY < Syskit::Composition
                argument :speed
                argument :x
                argument :y

                # The initial pose, as initially read from the pose child
                attr_reader :initial_pose
                # The trajectory that should be executed
                attr_reader :trajectory

                event :acquired_initial_pose

                add Rock::Services::Pose, as: 'pose'

                add(TrajectoryFollowerControl, as: 'trajectory').
                    use('pose' => pose_child).
                    with_arguments(trajectory: nil)

                script do
                    pose_reader = pose_child.pose_samples_port.reader
                    trajectory_writer = trajectory_child.trajectory_port.writer

                    # First, read the current pose
                    poll_until(acquired_initial_pose_event) do
                        if @initial_pose = pose_reader.read
                            acquired_initial_pose_event.emit
                        end
                    end

                    # Then generate a straight line between our current pose and
                    # the target, and execute it
                    execute do
                        spline = SISL::Spline3.interpolate(
                            [Eigen::Vector3.new(initial_pose.position.x, initial_pose.position.y, 0),
                             Eigen::Vector3.new(x, y, 0)])

                        @trajectory = Types.base.Trajectory.new(
                            speed: speed,
                            spline: spline)
                    end
                    wait_until_ready trajectory_writer
                    poll do
                        trajectory_writer.write([trajectory])
                    end
                end
            end
        end
    end
end

