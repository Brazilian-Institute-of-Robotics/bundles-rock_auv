module RockAUV
    module AUVControlCalibration
        module Ui
            class PIDController < Qt::Widget
                attr_reader :ui

                attr_reader :current_setpoint
                attr_reader :setpoint_edit
                attr_reader :plot_widget
                attr_reader :pidstate_plot_widget
                attr_reader :pidsettings_widget
                attr_reader :setpoint_format

                def initialize(parent = nil, setpoint_format: "%.2g")
                    super(parent)

                    @ui = Vizkit.default_loader.load(File.expand_path('pid_controller.ui', File.dirname(__FILE__)))
                    layout = Qt::VBoxLayout.new(self)
                    layout.add_widget ui

                    @setpoint_edit = ui.setpoint_edit
                    @plot_widget = ui.plot_widget
                    plot_widget.title = ""
                    @pidstate_plot_widget = ui.pidstate_plot_widget
                    pidstate_plot_widget.title = ""
                    @pidsettings_widget = ui.pidsettings_widget
                    pidsettings_widget.extend Vizkit::QtTypelibExtension

                    @setpoint_format =
                        if setpoint_format.respond_to?(:to_str)
                            lambda { |v| setpoint_format % [v] }
                        else
                            setpoint_format
                        end
                    @current_setpoint = nil

                    connect pidsettings_widget, SIGNAL(:updated), self, SIGNAL(:pidSettingsChanged)
                    connect setpoint_edit, SIGNAL('editingFinished()'), self, SLOT('read_current_setpoint()')
                    connect ui.splitter, SIGNAL('splitterMoved(int,int)'), self, SIGNAL('splitterMoved()')
                end

                def move_splitter(sizes)
                    ui.splitter.sizes = sizes
                end

                def splitter_sizes
                    ui.splitter.sizes
                end

                signals 'splitterMoved()'
                signals 'pidSettingsChanged()'

                def update_pid_settings(settings)
                    pidsettings_widget.set(settings)
                end

                def current_pid_settings
                    pidsettings_widget.get
                end

                def setpoint=(value)
                    setpoint_edit.text = setpoint_format.call(value)
                    read_current_setpoint
                end

                def read_current_setpoint
                    begin
                        @current_setpoint = Float(setpoint_edit.text)
                    rescue ArgumentError
                        Qt::MessageBox.critical(self, "Job Start", "Setpoint value not a numerical value (#{setpoint_edit.text})")
                        setpoint_edit.style_sheet = "QLineEdit { background: rgb(255,200,200); };"
                        return
                    end

                    setpoint_edit.style_sheet = ""
                    emit setpointChanged(current_setpoint)
                end
                slots 'read_current_setpoint()'
                signals 'setpointChanged(float)'

                def update_pid_state(state)
                    pidstate_plot_widget.update(state.P, "P", time: state.time)
                    pidstate_plot_widget.update(state.P + state.I, "P+I", time: state.time)
                    pidstate_plot_widget.update(state.P + state.I + state.D, "P+I+D", time: state.time)
                    pidstate_plot_widget.update(state.saturatedOutput, "Saturated", time: state.time)
                end

                def update_feedback(time, value)
                    plot_widget.update(current_setpoint, 'Target', time: time)
                    plot_widget.update(value, 'Current', time: time)
                end
            end
        end
    end
end


