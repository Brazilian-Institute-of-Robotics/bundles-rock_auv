require 'rock/models/services/pose'
require 'rock/models/services/trajectory_execution'
using_task_library 'trajectory_follower'
using_task_library 'auv_control'

module RockAUV
    module Compositions
        class TrajectoryFollower < Syskit::Composition
            add Rock::Services::Pose, as: 'pose'
            add OroGen::TrajectoryFollower::Task, as: 'follower'
            pose_child.connect_to follower_child

            add OroGen::AuvControl::MotionCommand2DConverter, as: 'converter'
            follower_child.connect_to converter_child

            export follower_child.trajectory_port
            provides Rock::Services::TrajectoryExecution, as: 'trajectory_execution'

            export converter_child.cmd_out_port
            provides Services::Controller.for { AlignedVel(:x, :yaw) }, as: 'aligned_vel_x_yaw_controller'
        end
    end
end
