require 'roby'
require 'syskit'
Roby.app.using 'syskit'
Roby.app.base_setup
require 'roby/interface/async'
require 'rock_auv/auv_control_calibration/ui/pid_controller'

module RockAUV
    module AUVControlCalibration
        module Ui
            class DumbZController < Qt::Widget
                attr_reader :syskit
                attr_reader :ui
                attr_reader :task_states
                attr_reader :controllers_layout
                attr_reader :controller_status_tabs

                attr_reader :controller_tasks

                Controller = Struct.new :name, :job_name, :job_argument_name,
                    :controller_task_name, :feedback_task_name, :feedback_port, :feedback_getter,
                    :format, :SI_to_ui, :ui_to_SI,
                    :update_pid_settings

                CONTROLLERS = [
                    Controller.new('Z', "direct_z_control_def",
                                   :z,
                                   'auv_control_world_pose2body_effort',
                                   'gazebo:underwater:flat_fish',
                                   'pose_samples',
                                   lambda { |pose| [pose.time, pose.position.z] },
                                   '%.2g',
                                   lambda { |z| z },
                                   lambda { |z| z },
                                   lambda { |settings, value| settings.linear[2] = value }),
                    Controller.new('Yaw',
                                   "direct_yaw_control_def",
                                   :yaw,
                                   'auv_control_world_pose2body_effort',
                                   'gazebo:underwater:flat_fish',
                                   'pose_samples',
                                   lambda { |pose| [pose.time, pose.orientation.yaw] },
                                   '%i',
                                   lambda { |rad| Integer(rad * 180 / Math::PI) },
                                   lambda { |deg| Float(deg) * Math::PI / 180 },
                                   lambda { |settings, value| settings.angular[2] = value }),
                ]

                def initialize(syskit, parent = nil, setpoint: 0)
                    super(parent)

                    Orocos.load_typekit 'auv_control'

                    @syskit = syskit
                    @ui = Vizkit.default_loader.load(File.expand_path('auv_calibration.ui', File.dirname(__FILE__)))
                    main_layout = Qt::VBoxLayout.new(self)
                    main_layout.add_widget ui

                    @controllers_layout  = Qt::GridLayout.new(ui.controllers_group)
                    @task_states = Vizkit.default_loader.StateViewer
                    task_states_layout = Qt::VBoxLayout.new(ui.tasks_group)
                    task_states_layout.add_widget task_states

                    @controller_status_tabs = ui.controller_status_tabs

                    @controller_tasks = Hash.new

                    CONTROLLERS.each do |ctrl|
                        add_controller(ctrl)
                    end

                    controller_status_tabs.current_widget.splitter_sizes

                    controller_status_tabs.connect(SIGNAL('currentChanged(int)')) do
                        w = controller_status_tabs.current_widget
                        @pid_settings_splitter_sizes ||= w.splitter_sizes
                        w.move_splitter(@pid_settings_splitter_sizes)
                    end
                end

                def add_controller(controller)
                    controller_task, settings_property, settings =
                        controller_tasks[controller.controller_task_name]
                    if !controller_task
                        controller_task = Orocos::Async.proxy(controller.controller_task_name)
                        settings_property = controller_task.property('pid_settings')
                        settings = Types.base.LinearAngular6DPIDSettings.new
                        controller_tasks[controller.controller_task_name] =
                            [controller_task, settings_property, settings]
                        settings_property.on_reachable do |*args|
                            settings_property.write(settings)
                        end
                    end

                    feedback_task   = Orocos::Async.proxy(controller.feedback_task_name)
                    task_states.add controller_task
                    task_states.add feedback_task

                    job_label = Qt::Label.new "<b>#{controller.name}</b>"
                    job_target   = Qt::Label.new "T:-"
                    job_feedback = Qt::Label.new "C:-"
                    job_state = Vizkit.default_loader.StateViewer
                    job_start = Qt::PushButton.new "Go"
                    job_kill  = Qt::PushButton.new "Kill"

                    row = controllers_layout.row_count
                    controllers_layout.add_widget(job_label, row, 0)
                    controllers_layout.add_widget(job_target, row, 1)
                    controllers_layout.add_widget(job_feedback, row, 2)
                    controllers_layout.add_widget(job_state, row, 3)
                    controllers_layout.add_widget(job_start, row, 4)
                    controllers_layout.add_widget(job_kill,  row, 5)

                    pid_controller = PIDController.new(self, setpoint_format: controller.format)
                    connect pid_controller, SIGNAL('splitterMoved()') do
                        @pid_settings_splitter_sizes = pid_controller.splitter_sizes
                    end
                    pid_controller.monitor(controller_task)
                    pid_controller.connect(SIGNAL(:pidSettingsChanged)) do
                        controller.update_pid_settings[settings, pid_controller.current_pid_settings]
                        begin
                            settings_property.write(settings)
                        rescue Orocos::NotFound, Orocos::ComError
                        end
                    end
                    controller_status_tabs.add_tab pid_controller, controller.name

                    job_state.update :INIT,
                        "#{controller.job_name}!",
                        job_state.unreachable_color

                    connect pid_controller, SIGNAL('setpointChanged(float)') do |val|
                        job_target.text = "T:#{controller.format}" % [val]
                    end

                    job = syskit.connect_to_ui(self) do
                        on_reachable do
                            job_start.show
                            job_kill.show
                        end
                        on_unreachable do
                            job_start.hide
                            job_kill.hide
                        end

                        job = send("#{controller.job_name}!")
                        connect job_start, SIGNAL(:clicked), START(job), restart: true
                        connect job_kill, SIGNAL(:clicked), KILL(job)
                        connect pid_controller, SIGNAL('setpointChanged(float)'), ARGUMENT(job, controller.job_argument_name),
                            getter: controller.ui_to_SI
                        connect PROGRESS(job) do |j|
                            update_job_state(job_state, j)
                        end
                        job
                    end

                    pid_controller.connect_to_task controller_task do
                        connect PORT(:pid_state), METHOD(:update_pid_state)
                    end
                    pid_controller.connect_to_task feedback_task do
                        connect PORT(controller.feedback_port) do |sample|
                            time, value = controller.feedback_getter[sample]
                            value = controller.SI_to_ui[value]
                            if !job.arguments[controller.job_argument_name.to_sym]
                                pid_controller.setpoint = value
                            end
                            pid_controller.update_feedback(time, value)
                            job_feedback.text = "C:#{controller.format}" % [value]
                        end
                    end
                end

                def update_job_state(job_state ,job)
                    state = job.state
                    state_name = state.to_s.upcase
                    if state == :unreachable
                        color = task_states.unreachable_color
                    elsif state == :reachable || Roby::Interface.terminal_state?(job.state)
                        color = task_states.reachable_color
                    else
                        color = task_states.running_color
                        state_name += "(ID=#{job.job_id})"
                    end

                    job_state.update state_name,
                        "#{job.action_name}!",
                        color
                end
            end
        end
    end
end

