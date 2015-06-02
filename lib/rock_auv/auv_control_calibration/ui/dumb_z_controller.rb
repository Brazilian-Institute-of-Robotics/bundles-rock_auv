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

                    connect setpoint_edit, SIGNAL(:returnPressed), self, SLOT(:start_job)
                    connect pidsettings_widget, SIGNAL(:updated), self, SIGNAL(:pidSettingsChanged)
                end

                signals 'setpointChanged()', 'pidSettingsChanged()'

                def syskit_job_name
                    "direct_z_control_def"
                end

                def monitor(position, depth_controller, syskit)
                    @syskit = syskit

                    connect_to_task depth_controller do
                        connect PORT(:pid_state), METHOD(:update_pid_state)
                    end
                    connect_to_task position do
                        connect PORT(:pose_samples), METHOD(:update_pose)
                    end

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

                    syskit.on_reachable do |jobs|
                        job_start_button.enabled = true
                        job_start_button.text = "Go"
                        update_syskit_label("REACHABLE", :reachable_color)
                    end
                    syskit.on_unreachable do
                        job_start_button.enabled = false
                        job_start_button.text = "Syskit Unreachable"
                        @job = nil
                        update_syskit_label("UNREACHABLE", :unreachable_color)
                    end
                    syskit.on_job(action_name: syskit_job_name) do |new_job|
                        puts "ON JOB #{new_job.job_id}"
                        if !job || job.job_id != new_job
                            setpoint = new_job.task.action_arguments[:z]
                            @current_setpoint = setpoint
                            setpoint_edit.text = setpoint.to_s
                            monitor_job(new_job)
                        end
                    end

                    connect(job_start_button, SIGNAL(:clicked), self, SLOT(:start_job))
                    connect(job_kill_button, SIGNAL(:clicked), self, SLOT(:kill_job))
                end

                def start_job
                    @current_setpoint =
                        begin
                            Float(setpoint_edit.text)
                        rescue ArgumentError
                            Qt::MessageBox.critical(self, "Job Start", "Setpoint value not a numerical value (#{setpoint_edit.text})")
                            return
                        end

                    batch = syskit.client.create_batch
                    if job && job.running?
                        batch.kill_job(job.job_id)
                    end
                    batch.send("#{syskit_job_name}!", z: @current_setpoint)

                    job = syskit.monitor_job(batch.process.last)
                    monitor_job(job)
                    emit setpointChanged
                end
                slots 'start_job()'

                def monitor_job(new_job)
                    @job = new_job
                    new_job.on_progress do
                        if job == new_job
                            update_job_state(new_job.state)
                        end
                    end
                    update_job_state(new_job.state)
                    new_job.start
                end

                def kill_job
                    if job.running?
                        job.kill
                    end
                end
                slots 'kill_job()'

                def update_syskit_label(state, color_name)
                    state_name = state.to_s.upcase
                    if job
                        state_name += "(ID=#{job.job_id})"
                    end

                    task_states_widget.update state_name, "syskit:#{syskit_job_name}!",
                        task_states_widget.send(color_name)
                end

                def update_job_state(state)
                    if Roby::Interface.terminal_state?(state)
                        update_syskit_label(state, :reachable_color)
                    else
                        update_syskit_label(state, :running_color)
                    end
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

