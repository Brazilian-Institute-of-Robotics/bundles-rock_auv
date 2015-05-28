using_task_library 'auv_control'

module OroGen
    module AuvControl

        describe Base do
            # Base cannot be instanciated, use PIDController for these tests
            # instead

            use_syskit_model PIDController
            it_should_be_configurable

            describe "#configure" do
                use_syskit_model PIDController

                it "creates the input ports as requested by the instanciated dynamic services" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                    model.require_dynamic_service("in_world_pos", as: 'yaw', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:yaw) })
                    task = deploy_and_configure(model)
                    assert task.orocos_task.has_port?('cmd_in_depth'), "expected a port called cmd_in_depth to have been created by the #configure method of #{task}, but #{task} only has #{task.orocos_task.enum_for(:each_input_port).map(&:name).sort.join(", ")}"
                    assert task.orocos_task.has_port?('cmd_in_yaw'), "expected a port called cmd_in_yaw to have been created by the #configure method of #{task}, but #{task} only has #{task.orocos_task.enum_for(:each_input_port).map(&:name).sort.join(", ")}"
                end

                it "sets the expected inputs property based on the instanciated dynamic services" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                    model.require_dynamic_service("in_world_pos", as: 'yaw', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:yaw) })
                    task = deploy_and_configure(model)
                    expected = task.orocos_task.expected_inputs
                    assert_equal [false, false, true], expected.linear.to_a
                    assert_equal [true, false, false], expected.angular.to_a
                end
            end

            describe ".world_frame?" do
                use_syskit_model PIDController

                it "returns true if the controller's inputs are in the world frame" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                    assert model.world_frame?
                end

                it "returns false if the controller's inputs are not in the world frame" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_aligned_vel", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { AlignedVel(:z) })
                    assert !model.world_frame?
                end

                it "fails configuration if required to process inputs from different reference frames" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'vel_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) })
                    model.require_dynamic_service("in_aligned_pos", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { AlignedPos(:z) })
                    assert_raises(ArgumentError) { model.world_frame? }
                end
            end

            describe ".position_control?" do
                use_syskit_model PIDController

                it "returns true if the controller's inputs are positions" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                    assert model.position_control?
                end

                it "returns false if the controller's inputs are not positions" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) })
                    assert !model.position_control?
                end

                it "fails configuration if required to process inputs from different domains" do
                    model = PIDController.specialize
                    model.require_dynamic_service("in_world_vel", as: 'vel_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) })
                    model.require_dynamic_service("in_world_pos", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                    assert_raises(ArgumentError) { model.position_control? }
                end
            end
        end

        describe PIDController do
            it_should_be_configurable

            describe "#configure" do
                attr_reader :model
                before do
                    @model = PIDController.specialize
                    model.require_dynamic_service("in_world_pos", as: 'depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldPos(:z) })
                end

                it "sets world_frame to the value of world_frame? (false)" do
                    task = deploy(model)
                    flexmock(task.model).should_receive(:world_frame?).once.and_return(false)
                    assert !syskit_setup_component(task).orocos_task.world_frame
                end

                it "sets world_frame to the value of world_frame? (true)" do
                    task = deploy(model)
                    flexmock(task.model).should_receive(:world_frame?).once.and_return(true)
                    assert syskit_setup_component(task).orocos_task.world_frame
                end

                it "sets position_control to the value of position_control? (false)" do
                    task = deploy(model)
                    flexmock(task.model).should_receive(:position_control?).once.and_return(false)
                    assert !syskit_setup_component(task).orocos_task.position_control
                end

                it "sets position_control to the value of position_control? (true)" do
                    task = deploy(model)
                    flexmock(task.model).should_receive(:position_control?).once.and_return(true)
                    assert syskit_setup_component(task).orocos_task.position_control
                end

                it "fails configuration if required to process inputs from different domains" do
                    model.require_dynamic_service("in_world_vel", as: 'pos_depth', control_domain_srv: RockAUV::Services::ControlledSystem.for { WorldVel(:z) })
                    assert_raises(Roby::MissionFailedError) { deploy_and_configure(model) }
                end
            end
        end

        #describe BasePIDController do
        #    # Base cannot be instanciated, use PIDController for these tests
        #    # instead
        #    use_syskit_model PIDController

        #    it_should_be_configurable
        #end

        #describe WorldToAligned do
        #    it_should_be_configurable
        #end

        #describe AlignedToBody do
        #    it_should_be_configurable
        #end

        #describe AccelerationController do
        #    it_should_be_configurable
        #end

        #describe ConstantCommand do
        #    it_should_be_configurable
        #end

        #describe ConstantCommandGroundFollower do
        #    it_should_be_configurable
        #end

        #describe WaypointNavigator do
        #    it_should_be_configurable
        #end

        #describe MotionCommand2DConverter do
        #    it_should_be_configurable
        #end

        #describe OptimalHeadingController do
        #    it_should_be_configurable
        #end

    end
end
