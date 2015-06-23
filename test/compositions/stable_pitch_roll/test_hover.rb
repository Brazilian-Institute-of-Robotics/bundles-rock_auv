require 'models/compositions/stable_pitch_roll/hover'

module RockAUV
    module Compositions
        module StablePitchRoll
            describe Hover do
                attr_reader :cmp_task, :initial_position

                before do
                    @cmp_task = syskit_stub_and_deploy(Hover, recursive: true)
                    syskit_configure_and_start(cmp_task, recursive: false)
                    syskit_configure_and_start(cmp_task.xy_samples_child, recursive: false)

                    @initial_position = Types.base.samples.RigidBodyState.new
                    initial_position.position = Eigen::Vector3.new(1, 2, 3)
                end

                it "does not set the controller's setpoint at deployment time" do
                    assert cmp_task.xy_control_child.partially_instanciated?
                end

                it "waits until an initial pose has been found" do
                    cmp_task.xy_samples_child.orocos_task.position_samples.write initial_position
                    assert_event_emission cmp_task.acquired_initial_position_event
                    assert_equal initial_position, cmp_task.initial_position
                end

                it "writes the initial pose as argument to the underlying XY controller" do
                    cmp_task.xy_samples_child.orocos_task.position_samples.write initial_position
                    assert_event_emission cmp_task.acquired_initial_position_event
                    assert_equal Hash[x: 1, y: 2],
                        cmp_task.xy_control_child.setpoint
                    syskit_configure_and_start(cmp_task.xy_samples_child, recursive: true)
                end
            end
        end
    end
end
