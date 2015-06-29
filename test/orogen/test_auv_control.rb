using_task_library 'auv_control'

module OroGen
    module AuvControl

        describe Base do
            # Base cannot be instanciated, use PIDController for these tests
            # instead

            use_syskit_model PIDController
            it { is_configurable }

            def connect_cmd_in(port)
                dummy_task_m = Syskit::TaskContext.new_submodel do
                    output_port 'out', '/base/LinearAngular6DCommand'
                end
                plan.add_mission(dummy_task = dummy_task_m.new)
                dummy_task.out_port.connect_to port
                dummy_task.out_port
            end

            describe "#configure" do
                use_syskit_model PIDController

                it "creates the input ports as requested by the instanciated dynamic services" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth',
                        control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) },
                        port_name: 'test_depth')
                    model.require_dynamic_service("in_world_pos", as: 'yaw',
                        control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:yaw) },
                        port_name: 'test_yaw')
                    task = syskit_stub_deploy_and_configure(model)

                    assert task.orocos_task.has_port?('cmd_in_test_depth'), "expected a port called cmd_in_test_depth to have been created by the #configure method of #{task}, but #{task} only has #{task.orocos_task.enum_for(:each_input_port).map(&:name).sort.join(", ")}"
                    assert task.orocos_task.has_port?('cmd_in_test_yaw'), "expected a port called cmd_in_test_yaw to have been created by the #configure method of #{task}, but #{task} only has #{task.orocos_task.enum_for(:each_input_port).map(&:name).sort.join(", ")}"
                end

                it "sets the expected inputs property based on the connected dynamic services" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test_depth')
                    model.require_dynamic_service("in_world_pos", as: 'yaw', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:yaw) }, port_name: 'test_yaw')
                    task = syskit_deploy(model)
                    connect_cmd_in(task.cmd_in_test_depth_port)
                    syskit_configure(task)

                    expected = task.orocos_task.expected_inputs
                    assert_equal [false, false, true], expected.linear.to_a
                    # Yaw input is not connected
                    assert_equal [false, false, false], expected.angular.to_a
                end

                it "propagates changes in expected inputs along the control chain" do
                    pos_controller_m = PIDController.specialize
                    pos_controller_m.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test')
                    pos_controller_m.add_output(as: 'vel') { WorldVel(:z) }
                    vel_controller_m = PIDController.specialize
                    vel_controller_m.require_dynamic_service("in_world_vel", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) }, port_name: 'test')

                    use_deployment PIDController => ['pos_test', 'vel_test']
                    pos_controller = syskit_deploy(pos_controller_m.prefer_deployed_tasks('pos_test'))
                    vel_controller = syskit_deploy(vel_controller_m.prefer_deployed_tasks('vel_test'))
                    pos_controller.cmd_out_port.connect_to vel_controller.cmd_in_test_port

                    syskit_configure(pos_controller)
                    syskit_configure(vel_controller)
                    assert_equal [false, false, false], vel_controller.expected_inputs.linear.to_a

                    dummy_port = connect_cmd_in(pos_controller.cmd_in_test_port)
                    pos_controller.update_expected_inputs
                    assert_equal [false, false, true], vel_controller.expected_inputs.linear.to_a

                    dummy_port.disconnect_from pos_controller.cmd_in_test_port
                    pos_controller.update_expected_inputs
                    assert_equal [false, false, false], vel_controller.expected_inputs.linear.to_a
                end
            end

            describe ".world_frame?" do
                use_syskit_model PIDController

                it "returns true if the controller's inputs are in the world frame" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test')
                    assert model.world_frame?
                end

                it "returns false if the controller's inputs are not in the world frame" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_aligned_vel", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { AlignedVel(:z) }, port_name: 'test')
                    assert !model.world_frame?
                end

                it "fails configuration if required to process inputs from different reference frames" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'vel_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) }, port_name: 'test_world_vel')
                    model.require_dynamic_service("in_aligned_pos", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { AlignedPos(:z) }, port_name: 'test_aligned_pos')
                    assert_raises(RockAUV::Services::Control::Domain::ComplexDomainError) { model.world_frame? }
                end
            end

            describe ".position_control?" do
                use_syskit_model PIDController

                it "returns true if the controller's inputs are positions" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test')
                    assert model.position_control?
                end

                it "returns false if the controller's inputs are not positions" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) }, port_name: 'test')
                    assert !model.position_control?
                end

                it "fails configuration if required to process inputs from different domains" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'vel_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) }, port_name: 'test_world_vel')
                    model.require_dynamic_service("in_world_pos", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test_world_pos')
                    assert_raises(RockAUV::Services::Control::Domain::ComplexDomainError) { model.position_control? }
                end
            end
            describe "#each_input_domain" do
                use_syskit_model PIDController

                attr_reader :base_m, :source_m, :base, :source
                before do
                    base_m = Base
                    base_m = base_m.add_input(as: 'depth', port_name: 'depth') { WorldPos(:z) }
                    base_m = base_m.add_input(as: 'forward', port_name: 'forward') { WorldPos(:x) }
                    @base_m = base_m
                    @source_m = Syskit::TaskContext.new_submodel do
                        output_port 'out', '/base/LinearAngular6DCommand'
                    end
                    plan.add(@source = source_m.new)
                    plan.add(@base = base_m.new)
                end

                it "yields only ports that are connected" do
                    source.out_port.connect_to base.cmd_in_depth_port
                    z_domain = RockAUV::Services::Control.Domain { WorldPos(:z) }
                    assert_equal [[base.cmd_in_depth_port, z_domain, base.depth_srv]],
                        base.each_input_domain.to_a
                end

                it "yields a port as many times as there are services for it" do
                    base.specialize
                    base.model.add_input(as: 'depth2', port_name: 'depth') { WorldPos(:z) }
                    z_domain = RockAUV::Services::Control.Domain { WorldPos(:z) }

                    source.out_port.connect_to base.cmd_in_depth_port
                    assert_equal [[base.cmd_in_depth_port, z_domain, base.depth_srv],
                                  [base.cmd_in_depth_port, z_domain, base.depth2_srv]].to_set,
                        base.each_input_domain.to_set
                end
                it "yields the domains as projected on the service's domain" do
                end
            end

            describe "dynamic handling of dynamic services" do
                it "creates new ports on the task if services get created on an already-configured task" do
                    task = syskit_deploy_and_configure(subject_syskit_model)
                    task.specialize
                    flexmock(task.orocos_task).should_receive(:addCommandInput).
                        once.with('in_test', any).
                        pass_thru
                    task.require_dynamic_service(
                        "in_world_pos", as: 'depth',
                        control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) },
                        port_name: 'test')
                    assert task.orocos_task.has_port?('cmd_in_test')
                end

                it "does not create a new port if it already exists" do
                    task = syskit_deploy_and_configure(subject_syskit_model)
                    task.specialize
                    flexmock(task.orocos_task).should_receive(:addCommandInput).
                        once.with('in_test', any).
                        pass_thru
                    2.times do
                        task.require_dynamic_service(
                            "in_world_pos", as: 'depth',
                            control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) },
                            port_name: 'test')
                    end
                end
            end

            describe "the addCommandInput operation" do
                it "creates a port named cmd_{arg}" do
                    task = syskit_deploy_and_configure(subject_syskit_model)
                    task.orocos_task.addCommandInput('test', 0)
                    assert task.orocos_task.has_port?('cmd_test')
                end
            end
        end

        describe PIDController do
            it { is_configurable }

            describe "#configure" do
                attr_reader :model
                before do
                    @model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) }, port_name: 'test')
                end

                it "sets world_frame to the value of world_frame? (false)" do
                    task = syskit_deploy(model)
                    flexmock(task.model).should_receive(:world_frame?).once.and_return(false)
                    assert !syskit_configure(task).orocos_task.world_frame
                end

                it "sets world_frame to the value of world_frame? (true)" do
                    task = syskit_deploy(model)
                    flexmock(task.model).should_receive(:world_frame?).once.and_return(true)
                    assert syskit_configure(task).orocos_task.world_frame
                end

                it "sets position_control to the value of position_control? (false)" do
                    task = syskit_deploy(model)
                    flexmock(task.model).should_receive(:position_control?).once.and_return(false)
                    assert !syskit_configure(task).orocos_task.position_control
                end

                it "sets position_control to the value of position_control? (true)" do
                    task = syskit_deploy(model)
                    flexmock(task.model).should_receive(:position_control?).once.and_return(true)
                    assert syskit_configure(task).orocos_task.position_control
                end

                it "fails configuration if required to process inputs from different domains" do
                    model.require_dynamic_service("in_world_vel", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) }, port_name: 'test_world_vel')
                    assert_raises(RockAUV::Services::Control::Domain::ComplexDomainError) { syskit_deploy_and_configure(model) }
                end
            end

            describe "#can_merge?" do
                attr_reader :left_source, :right_source
                before do
                    source_m = Syskit::TaskContext.new_submodel do
                        output_port 'out', '/base/LinearAngular6DCommand'
                    end
                    plan.add(@left_source = source_m.new)
                    plan.add(@right_source = source_m.new)
                end
                it "returns true if the input domains are compatible" do
                    left  = PIDController.add_input(as: 'depth', port_name: 'z') { WorldPos(:z) }.new
                    right = PIDController.add_input(as: 'heading', port_name: 'yaw') { WorldPos(:yaw) }.new
                    left_source.out_port.connect_to left.cmd_in_z_port
                    right_source.out_port.connect_to right.cmd_in_yaw_port
                    assert left.can_merge?(right)
                end

                it "returns false if the input domains are not compatible" do
                    left  = PIDController.add_input(as: 'depth', port_name: 'y')     { WorldPos(:y) }.new
                    right = PIDController.add_input(as: 'forward', port_name: 'xy') { WorldPos(:x, :y) }.new
                    left_source.out_port.connect_to left.cmd_in_y_port
                    right_source.out_port.connect_to right.cmd_in_xy_port
                    assert !left.can_merge?(right)
                end

                it "only compares the disjoint parts of the domain" do
                    left  = PIDController.add_input(as: 'depth', port_name: 'y') { WorldPos(:y) }.new
                    right = PIDController.add_input(as: 'heading', port_name: 'yaw') { WorldPos(:yaw) }.new
                    right.specialize
                    right.model.add_input(as: 'depth') { WorldPos(:y) }
                    left_source.out_port.connect_to left.cmd_in_y_port
                    right_source.out_port.connect_to right.cmd_in_yaw_port
                    assert left.can_merge?(right)
                end
            end

            describe "#merge" do
                it "has a full input domain which is the union of the two" do
                    left_m  = PIDController.add_input(as: 'depth') { WorldPos(:z) }
                    right_m = PIDController.add_input(as: 'heading') { WorldPos(:yaw) }
                    plan.add(left = left_m.new)
                    plan.add(right = right_m.new)
                    left.merge(right)
                    assert_equal (RockAUV::Services::Control.Domain { WorldPos(:z,:yaw) }),
                        left.model.full_input_domain
                end
                it "has a full output domain which is the union of the two" do
                    left_m = PIDController.add_output(as: :body_effort_z) { BodyEffort(:z) }
                    right_m = PIDController.add_output(as: :body_effort_heading) { BodyEffort(:yaw) }
                    plan.add(left = left_m.new)
                    plan.add(right = right_m.new)
                    left.merge(right)
                    assert_equal (RockAUV::Services::Control.Domain { BodyEffort(:z,:yaw) }),
                        left.model.full_output_domain
                end
            end
        end

        #describe BasePIDController do
        #    # Base cannot be instanciated, use PIDController for these tests
        #    # instead
        #    use_syskit_model PIDController

        #    it { is_configurable }
        #end

        #describe WorldToAligned do
        #    it { is_configurable }
        #end

        #describe AlignedToBody do
        #    it { is_configurable }
        #end

        #describe AccelerationController do
        #    it { is_configurable }
        #end

        #describe ConstantCommand do
        #    it { is_configurable }
        #end

        #describe ConstantCommandGroundFollower do
        #    it { is_configurable }
        #end

        #describe WaypointNavigator do
        #    it { is_configurable }
        #end

        #describe MotionCommand2DConverter do
        #    it { is_configurable }
        #end

        #describe OptimalHeadingController do
        #    it { is_configurable }
        #end

    end
end
