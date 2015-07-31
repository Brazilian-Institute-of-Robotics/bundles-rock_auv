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
            end
        end
    end
end
