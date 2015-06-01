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
                attr_reader :job_id

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
                        update_state_from_syskit(jobs)
                    end
                    syskit.on_unreachable do
                        job_start_button.enabled = false
                        job_start_button.text = "Syskit Unreachable"

                        @job_id = nil
                        update_syskit_label("UNREACHABLE", :unreachable_color)
                    end
                    connect(job_start_button, SIGNAL(:clicked), self, SLOT(:start_job))
                    connect(job_kill_button, SIGNAL(:clicked), self, SLOT(:kill_job))

                    syskit.on_job_progress do |state, job_id, job_name, _|
                        if job_id == self.job_id
                            update_job_state(state)
                        end
                    end
                end

                def find_existing_job(jobs = syskit.client.jobs)
                    if j = jobs.find { |_, (_, _, job_task)| job_task.action_model.name == syskit_job_name }
                        job_id, (job_state, _, job_task) = *j
                        return job_id, job_state, job_task.action_arguments[:z]
                    end
                end

                def update_state_from_syskit(jobs = self.syskit.client.jobs)
                    job_id, job_state, job_setpoint = find_existing_job
                    if job_id
                        @job_id = job_id
                        @current_setpoint = job_setpoint
                        setpoint_edit.text = job_setpoint.to_s
                        update_job_state(job_state)
                    end
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
                    if job_id
                        batch.kill_job(job_id)
                    end
                    batch.send("#{syskit_job_name}!", z: @current_setpoint)
                    @job_id = batch.process.last
                    emit setpointChanged
                end
                slots 'start_job()'

                def kill_job
                    if job_id
                        syskit.client.kill_job(job_id)
                        @job_id = nil
                        # in case there was more than one job running ...
                        update_state_from_syskit
                    end
                end
                slots 'kill_job()'

                def update_syskit_label(state, color_name)
                    state_name = state.to_s.upcase
                    if job_id
                        state_name += "(ID=#{job_id})"
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

