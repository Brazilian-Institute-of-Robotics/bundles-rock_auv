module RockAUV
    module AUVControlCalibration
        class CLI < Thor
            desc "init", "creates the necessary configuration(s) to run 'calibrate'"
            def init
                require 'rock_auv/auv_control_calibration/ui/init'

                w = Qt::Widget.new
                ui = Ui::Init.new
                ui.setup_ui(w)

                if !ui.selected_conf
                    ui.generate_from_sdf
                end
                w.show
                Vizkit.exec
            end

            desc 'calibrate', "run the calibration UI"
            def calibrate
                require 'rock_auv/auv_control_calibration/ui/calibrate'
                Roby.app.using 'syskit'
                Roby.app.base_setup
                Roby.app.setup_dirs
                Bundles.initialize

                syskit = Roby::Interface::Async::Interface.new
                w = Ui::Calibrate.new(syskit)
                w.resize 1024,768
                w.show

                syskit_poll = Qt::Timer.new
                syskit_poll.connect(SIGNAL('timeout()')) do
                    syskit.poll
                end
                syskit_poll.start(10)

                Vizkit.exec

            end
        end
    end
end
