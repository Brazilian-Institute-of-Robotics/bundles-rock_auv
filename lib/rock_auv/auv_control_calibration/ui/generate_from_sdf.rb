require 'rock_auv/auv_control_calibration/ui/ui_generate_from_sdf'

module RockAUV
    module AUVControlCalibration
        module Ui
            class GenerateFromSDF
                attr_reader :thrusters

                def setup_ui(main)
                    super
                    warn_zone.hide
                    model_list_group.hide

                    sdf_path_browse.connect(SIGNAL('clicked()')) do
                        SDF::XML.model_path = Bundles.find_dirs('data', 'gazebo', 'models', all: true, order: :specific_first)
                        if file = Qt::FileDialog.get_open_file_name(main, "SDF File", SDF::XML.model_path.first)
                            begin
                                @thrusters = AUVControlCalibration.sdf_load_thrusters_poses(file)
                                sdf_path_edit.text = file
                                warn_hide
                            rescue Exception => e
                                warn "invalid SDF file: #{e.message}"
                            end
                        end
                    end

                    button_box.connect(SIGNAL('accepted()')) do
                        if conf_name_edit.text.empty?
                            warn "empty configuration name"
                        elsif !File.file?(sdf_path_edit.text)
                            warn "SDF file path does not exist"
                        else
                            main.accept
                        end
                    end
                end

                def warn_hide
                    warn_zone.hide
                end

                def warn(text)
                    warn_zone.show
                    warn_zone.style_sheet = "QLabel { background-color: red; }"
                    warn_zone.text = text
                end

                def thruster_names
                    thrusters.keys
                end

                def conf_name
                    conf_name_edit.text
                end

                def matrix
                    AUVControlCalibration.sdf_thrusters_to_matrix(thrusters.values)
                end

                def self.exec(parent)
                    dialog = Qt::Dialog.new(parent)
                    generator = new
                    generator.setup_ui(dialog)
                    if dialog.exec == Qt::Dialog::Accepted
                        return generator.conf_name,
                            generator.thruster_names,
                            generator.matrix
                    end
                end
            end
        end
    end
end
