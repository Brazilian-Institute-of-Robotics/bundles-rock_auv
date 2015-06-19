require 'roby'
require 'syskit'
require 'roby/interface/async'

module RockAUV
    module MotionUI
        class Main < Qt::Widget
            attr_reader :syskit
            attr_reader :ui
            attr_reader :task_states

            attr_reader :z_target
            attr_reader :yaw_target

            attr_reader :z_target_editor
            attr_reader :yaw_target_editor
            attr_reader :xy_target_editor

            attr_reader :z_current_display
            attr_reader :yaw_current_display
            attr_reader :xy_current_display

            def initialize(syskit, parent = nil)
                super(parent)

                # This will cause both the model(s) and the configuration to
                # be loaded
                Roby.app.using_task_library('auv_control')
                Orocos.load_typekit 'auv_control'

                @syskit = syskit
                @ui = Vizkit.default_loader.load(File.expand_path('main.ui', File.dirname(__FILE__)))
                @z_target_editor = ui.constant_z_target
                @yaw_target_editor = ui.constant_yaw_target
                @xy_target_editor = ui.goto_xy_target
                @z_current_display = ui.constant_z_current
                @yaw_current_display = ui.constant_yaw_current
                @xy_current_display = ui.goto_xy_current
                main_layout = Qt::VBoxLayout.new(self)
                main_layout.add_widget ui

                @task_states = Vizkit.default_loader.StateViewer
                task_states_layout = Qt::VBoxLayout.new(ui.tasks_group)
                task_states_layout.add_widget task_states

                jobs = Hash.new
                %w{constant_z constant_yaw goto_xy}.each do |definition_name|
                    jobs[definition_name] = connect_to_definition(definition_name)
                end

                connect ui.constant_yaw_target, SIGNAL('editingFinished()'),
                    self, SLOT(:read_yaw_target)
                connect ui.constant_z_target, SIGNAL('editingFinished()'),
                    self, SLOT(:read_z_target)
                connect ui.goto_xy_target, SIGNAL('editingFinished()'),
                    self, SLOT(:read_xy_target)

                xy_setpoint = Hash[]
                syskit.connect_to_ui(self) do
                    connect widget, SIGNAL('z_target_changed(float)'),
                        ARGUMENT(jobs['constant_z'], :setpoint)
                    connect widget, SIGNAL('yaw_target_changed(float)'),
                        ARGUMENT(jobs['constant_yaw'], :setpoint)
                    connect widget, SIGNAL('speed_changed(float)'),
                        ARGUMENT(jobs['goto_xy'], :speed)
                    connect widget, SIGNAL('x_target_changed(float)'),
                        ARGUMENT(jobs['goto_xy'], :setpoint),
                        getter: lambda { |x| xy_setpoint.merge!(x: x) }
                    connect widget, SIGNAL('y_target_changed(float)'),
                        ARGUMENT(jobs['goto_xy'], :setpoint),
                        getter: lambda { |y| xy_setpoint.merge!(y: y) }
                end
                emit speed_changed(0.1)
                read_z_target
                read_xy_target
                read_yaw_target
            end

            signals 'z_target_changed(float)',
                'yaw_target_changed(float)',
                'x_target_changed(float)',
                'y_target_changed(float)',
                'speed_changed(float)'

            slots 'read_z_target()',
                'read_yaw_target()',
                'read_xy_target()'

            def read_z_target
                if target = read_scalar_target(z_target_editor)
                    @z_target = target
                    emit z_target_changed(z_target)
                end
            end

            def read_yaw_target
                if target = read_scalar_target(yaw_target_editor)
                    target = target * Math::PI / 180
                    @yaw_target = target
                    emit yaw_target_changed(yaw_target)
                end
            end

            def read_scalar_target(editor)
                begin
                    result = Float(editor.text)
                rescue ArgumentError
                    Qt::MessageBox.critical(self, "Job Start", "Setpoint value not a numerical value (#{editor.text})")
                    editor.style_sheet = "QLineEdit { background: rgb(255,200,200); };"
                    return
                end

                editor.style_sheet = ""
                result
            end

            def read_xy_target
                begin
                    string = xy_target_editor.text
                    x, y = string.split('/')
                    if !y
                        Kernel.raise ArgumentError, "no '/' in setpoint"
                    end
                    x = Float(x)
                    y = Float(y)
                rescue ArgumentError
                    Qt::MessageBox.critical(self, "Job Start", "Setpoint value not in x/y format (#{xy_target_editor.text})")
                    xy_target_editor.style_sheet = "QLineEdit { background: rgb(255,200,200); };"
                    return
                end

                xy_target_editor.style_sheet = ""
                emit x_target_changed(x)
                emit y_target_changed(y)
            end

            def connect_to_definition(definition_name)
                job_state = Vizkit.default_loader.StateViewer
                job_state.set_size_policy(Qt::SizePolicy::MinimumExpanding, Qt::SizePolicy::Minimum)
                job_state.update :INIT,
                    "#{definition_name}_def!",
                    job_state.unreachable_color
                ui.send("#{definition_name}_layout").insert_widget(4, job_state)

                job_start = ui.send("#{definition_name}_go")
                job_kill  = ui.send("#{definition_name}_kill")
                syskit.connect_to_ui(self) do
                    on_reachable do
                        job_start.show
                        job_kill.show
                    end
                    on_unreachable do
                        job_start.hide
                        job_kill.hide
                    end

                    job = send("#{definition_name}_def!")
                    connect job_start, SIGNAL(:clicked), START(job), restart: true
                    connect job_kill, SIGNAL(:clicked), KILL(job)
                    connect PROGRESS(job) do |j|
                        update_job_state(job_state, j)
                    end
                    job
                end
            end

            def update_job_state(job_state, job)
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

            def watch_orocos_task(task)
                task_states.add task
            end

            def update_pose(pose)
                z_current_display.text = "%.2f" % [pose.position.z]
                yaw_current_display.text = "%i" % [pose.orientation.yaw * 180 / Math::PI]
                xy_current_display.text = "%.2f/%.2f" % [pose.position.x,pose.position.y]
                ui.orientation.update(pose, '')
            end
        end
    end
end

