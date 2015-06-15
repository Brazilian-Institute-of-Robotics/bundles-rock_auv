require 'models/compositions/stable_pitch_roll/goto_xy'

module RockAUV
    module Compositions
        module StablePitchRoll
            describe GotoXY do
                attr_reader :cmp_task, :initial_pose

                before do
                    goto_xy_m = GotoXY.with_arguments(x: 10, y: 20, speed: 0.1)
                    @cmp_task = stub_deploy_and_start(goto_xy_m, recursive: true)

                    @initial_pose = Types.base.samples.RigidBodyState.new
                    initial_pose.position = Eigen::Vector3.new(1, 2, 3)
                end

                it "waits until an initial pose has been found" do
                    cmp_task.pose_child.orocos_task.pose_samples.write initial_pose
                    assert_event_emission cmp_task.acquired_initial_pose_event
                    assert_equal initial_pose, cmp_task.initial_pose
                end

                it "generates a trajectory and outputs it" do
                    cmp_task.pose_child.orocos_task.pose_samples.write initial_pose
                    assert_event_emission cmp_task.acquired_initial_pose_event

                    trajectory = assert_has_one_new_sample(
                        cmp_task.trajectory_child.trajectory_port)
                    trajectory = trajectory.first
                    assert_in_delta 0.1, trajectory.speed, 1e-4
                    binding.pry
                    assert Eigen::Vector3.new(1, 2, 0).approx?(trajectory.spline.start_point)
                    assert Eigen::Vector3.new(10, 20, 0).approx?(trajectory.spline.end_point)
                end
            end
        end
    end
end
