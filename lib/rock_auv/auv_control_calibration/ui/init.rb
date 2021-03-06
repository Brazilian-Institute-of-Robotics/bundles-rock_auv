require 'rock_auv/auv_control_calibration/sdf_to_matrix'
require 'rock_auv/auv_control_calibration/ui/generate_from_sdf'
require 'rock_auv/auv_control_calibration/ui/ui_init'

module RockAUV
    module AUVControlCalibration
        module Ui
            class Init
                attr_reader :config

                CONTROLLER_TASK_NAME = 'auv_control::AccelerationController'
                MATRIX_PROPERTY_NAME = 'matrix'
                NEW_CONF_TEXT = "-- Generate from SDF"

                def initialize
                    config = Orocos::ConfigurationManager.new
                    Bundles.find_dirs('config', 'orogen', all: true, order: :specific_last).each do |dir|
                        config.load_dir dir
                    end
                    loader = OroGen::Loaders::RTT.new
                    @config = (config.conf[CONTROLLER_TASK_NAME] ||=
                               Orocos::TaskConfigurations.new(loader.task_model_from_name(CONTROLLER_TASK_NAME)))
                end

                def config_dir
                    File.join(Bundles.config_dir, 'orogen')
                end

                def config_file
                    File.join(config_dir, "#{CONTROLLER_TASK_NAME}.yml")
                end

                def setupUi(main)
                    super

                    config.each_resolved_conf do |name, conf|
                        if conf[MATRIX_PROPERTY_NAME]
                            conf_chooser.add_item name
                        end
                    end
                    conf_chooser.add_item NEW_CONF_TEXT

                    conf_chooser.connect(SIGNAL('activated(QString)')) do |conf_name|
                        if conf_name == NEW_CONF_TEXT
                            file_name, conf_name, thruster_names, matrix = GenerateFromSDF.exec(main)
                            if conf_name
                                conf = Hash[
                                    'names' => thruster_names,
                                    'matrix' => matrix]

                                config.add conf_name, conf, merge: true
                                idx = conf_chooser.find_text(conf_name)
                                if idx == -1
                                    idx = conf_chooser.count - 1
                                    conf_chooser.insert_item(conf_chooser.count - 1, conf_name)
                                end
                                conf_chooser.current_index = idx
                                config.save conf_name, config_file
                                select_configuration(conf_name)
                            end
                        elsif conf_name
                            select_configuration(conf_name)
                        end
                    end

                    limits_button.connect(SIGNAL('clicked()')) do
                        if conf_chooser.current_index != -1
                            compute_limits(conf_chooser.current_text)
                        end
                    end

                    if conf_chooser.count > 1
                        conf_chooser.current_index = 0
                        select_configuration(conf_chooser.current_text)
                    else
                        conf_chooser.current_index = -1
                    end
                end

                def generate_from_sdf
                    conf_chooser.current_index = conf_chooser.count - 1
                end

                def selected_conf
                    conf = conf_chooser.current_text
                    if conf != NEW_CONF_TEXT
                        conf
                    end
                end

                def select_configuration(conf_name)
                    c = config.conf_as_ruby(conf_name)
                    matrix = c['matrix']
                    names  = c['names']

                    matrix_editor.row_count = matrix.rows
                    matrix_editor.column_count = matrix.cols
                    matrix_editor.horizontal_header_labels = names
                    matrix_editor.vertical_header_labels = %w{Fx Fy Fz Tx Ty Tz}
                    matrix.rows.times do |r|
                        matrix.cols.times do |c|
                            matrix_editor.setItem(r, c, Qt::TableWidgetItem.new(matrix[r,c].to_s))
                        end
                    end
                end

                def compute_limits(conf_name, sdf_file = nil)
                    if !sdf_file
                        sdf_file = Qt::FileDialog.get_open_file_name(nil, "SDF File", SDF::XML.model_path.first)
                        return if !sdf_file
                    end

                    c = config.conf_as_ruby(conf_name)
                    matrix = c['matrix']
                    names  = c['names']

                    effort_min = [0, 0, 0, 0, 0, 0]
                    effort_max = [0, 0, 0, 0, 0, 0]
                    limits = AUVControlCalibration.sdf_load_thruster_limits(sdf_file)
                    limits.each do |thruster_name, (min, max)|
                        thruster_efforts = []

                        col_idx = names.index(thruster_name)
                        6.times do |row_idx|
                            v = matrix[row_idx, col_idx]
                            thruster_min, thruster_max = [v * min, v * max].sort
                            effort_min[row_idx] += thruster_min
                            effort_max[row_idx] += thruster_max
                        end
                    end

                    limits_editor.row_count = 2
                    limits_editor.column_count = 6
                    limits_editor.horizontal_header_labels = %w{Fx Fy Fz Tx Ty Tz}
                    limits_editor.vertical_header_labels   = %w{Min Max}
                    effort_min.each_with_index do |e, i|
                        limits_editor.setItem(0, i, Qt::TableWidgetItem.new(e.to_s))
                    end
                    effort_max.each_with_index do |e, i|
                        limits_editor.setItem(1, i, Qt::TableWidgetItem.new(e.to_s))
                    end
                end
            end
        end
    end
end

