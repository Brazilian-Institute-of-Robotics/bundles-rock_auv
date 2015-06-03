require 'roby'
require 'syskit'
Roby.app.using 'syskit'
Roby.app.base_setup
require 'roby/interface/async'

module RockAUV
    module AUVControlCalibration
        module Ui
            class DumbZController < Qt::Widget
                def self.monitor(position, depth_controller, syskit, parent: nil)
                    ui = new(parent)
                    ui.monitor(position, depth_controller, syskit)
                    ui
                end

                attr_reader :ui
                attr_reader :current_setpoint
                attr_reader :setpoint_edit
                attr_reader :task_states_widget
                attr_reader :plot_widget
                attr_reader :pidstate_plot_widget
                attr_reader :pidsettings_widget
                attr_reader :job_start_button
                attr_reader :job_kill_button

                attr_reader :syskit
                attr_reader :job

                def current_pid_settings
                    pidsettings_widget.get
                end

                def initialize(parent = nil, setpoint: 0)
                    super(parent)

                    @task_states_widget = Vizkit.default_loader.StateViewer
                    task_states_widget.max_cols = 5
                    @ui = Vizkit.default_loader.load(File.expand_path('dumb_z_controller.ui', File.dirname(__FILE__)))

                    task_states_layout = Qt::HBoxLayout.new
                    task_states_layout.add_widget task_states_widget
                    task_states_layout.add_stretch

                    layout = Qt::VBoxLayout.new(self)
                    layout.add_layout task_states_layout
                    layout.add_widget ui

                    @setpoint_edit = ui.setpoint_edit
                    @plot_widget = ui.plot_widget
                    plot_widget.title = ""
                    @pidstate_plot_widget = ui.pidstate_plot_widget
                    pidstate_plot_widget.title = ""
                    @pidsettings_widget = ui.pidsettings_widget
                    @job_start_button = ui.job_start_button
                    @job_kill_button = ui.job_kill_button

                    @current_setpoint = setpoint
                    setpoint_edit.text = current_setpoint.to_s

                    connect pidsettings_widget, SIGNAL(:updated), self, SIGNAL(:pidSettingsChanged)
                end

                signals 'setpointChanged()', 'pidSettingsChanged()'

                def monitor(position, depth_controller, syskit)
                    @syskit = syskit

                    connect_to_task depth_controller do
                        connect PORT(:pid_state), METHOD(:update_pid_state)
                    end
                    connect_to_task position do
                        connect PORT(:pose_samples), METHOD(:update_pose)
                    end

                    task_states_widget.update :INIT,
                        "syskit:direct_z_control_def!",
                        task_states_widget.unreachable_color
                    task_states_widget.add position
                    task_states_widget.add depth_controller
                    pidsettings_widget.extend Vizkit::QtTypelibExtension

                    Orocos.load_typekit 'auv_control'
                    connect_to_task depth_controller do
                        connect SIGNAL(:pidSettingsChanged), PROPERTY(:pid_settings),
                            getter: lambda {
                                    settings = Types.base.LinearAngular6DPIDSettings.new
                                    settings.linear[2] = widget.current_pid_settings
                                    settings
                            }
                    end

                    syskit.connect_to_ui(self) do
                        on_reachable do |jobs|
                            job_start_button.enabled = true
                            job_start_button.text = "Go"
                        end
                        on_unreachable do
                            job_start_button.enabled = false
                            job_start_button.text = "Syskit Unreachable"
                        end

                        job = direct_z_control_def!
                        connect job_start_button, SIGNAL(:clicked), START(job), restart: true
                        connect job_kill_button, SIGNAL(:clicked), KILL(job)
                        connect widget, SIGNAL('setpointChanged(float)'), ARGUMENT(job, :z)
                        connect PROGRESS(job) do |j|
                            update_job_state(j)
                        end
                    end

                    connect setpoint_edit, SIGNAL('editingFinished()'), self, SLOT(:read_current_setpoint)
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

                def update_job_state(job)
                    state = job.state
                    state_name = state.to_s.upcase
                    if state == :unreachable
                        color = task_states_widget.unreachable_color
                    elsif state == :reachable || Roby::Interface.terminal_state?(job.state)
                        color = task_states_widget.reachable_color
                    else
                        color = task_states_widget.running_color
                        state_name += "(ID=#{job.job_id})"
                    end

                    task_states_widget.update state_name,
                        "syskit:#{job.action_name}!",
                        color
                end

                def update_pid_state(state)
                    state = state.linear[2]
                    pidstate_plot_widget.update(state.P, "P", time: state.time)
                    pidstate_plot_widget.update(state.P + state.I, "P+I", time: state.time)
                    pidstate_plot_widget.update(state.P + state.I + state.D, "P+I+D", time: state.time)
                    pidstate_plot_widget.update(state.saturatedOutput, "Saturated", time: state.time)
                end

                def update_pose(sample)
                    plot_widget.update(current_setpoint, 'Target Z', time: sample.time)
                    plot_widget.update(sample.position.z, 'Z', time: sample.time)
                end
            end
        end
    end
end

