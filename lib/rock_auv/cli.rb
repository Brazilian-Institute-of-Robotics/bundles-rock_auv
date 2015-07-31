require 'thor'
require 'rock_auv/auv_control_calibration/cli'

module RockAUV
    class CLI < Thor
        no_commands do
            def create_syskit_interface
                syskit = Roby::Interface::Async::Interface.new
                syskit_poll = Qt::Timer.new
                syskit_poll.connect(SIGNAL('timeout()')) do
                    syskit.poll
                end
                syskit_poll.start(10)
                syskit
            end

            def vizkit(w)
                w.resize 1024,768
                w.show
                Vizkit.exec
            end
        end

        desc 'control-calibration', 'access to the AUV control calibration tools'
        subcommand :control_calibration, AUVControlCalibration::CLI

        desc 'control FEEDBACK_TASK_NAME [FEEDBACK_PORT_NAME]',
            'start a control UI, using the given task/port for feedback. If no port is given, it uses the default of "port_samples"'
        def control(task, port = "pose_samples")
            require 'rock_auv/motion_ui/main'
            Roby.app.using 'syskit'
            Roby.app.base_setup
            Roby.app.setup_dirs
            Orocos.initialize

            task   = Orocos::Async.proxy(task)
            pose_port = task.port(port)
            syskit = create_syskit_interface

            w = RockAUV::MotionUI::Main.new(syskit)
            w.watch_orocos_task task
            pose_port.on_data do |sample|
                w.update_pose(sample)
            end
            vizkit(w)
        end
    end
end

