require 'models/compositions/constant_setpoint_generator'

module RockAUV
    module Compositions
        describe ConstantSetpointGenerator do
            attr_reader :setpoint, :out, :task_m

            before do
                @task_m = ConstantSetpointGenerator.for { WorldPos(:z) }
                @setpoint = Hash[z: 0]
                @out = Types.base.LinearAngular6DCommand.new(
                    time: Time.at(0),
                    linear: Eigen::Vector3.new(Base.unset, Base.unset, 0),
                    angular: Eigen::Vector3.new(Base.unset, Base.unset, Base.unset))
            end

            describe "#setpoint=" do
                it "sets the out value from a LinearAngular6DCommand object" do
                    plan.add(task = task_m.new(setpoint: setpoint))
                    assert_equal setpoint, task.arguments[:setpoint]
                end
                it "sets the ConstantGenerator's values parameter" do
                    plan.add(task = task_m.new(setpoint: setpoint))
                    assert_equal Hash['out' => out], task.arguments[:values]
                end
                it "raises ArgumentError if a field is set that is not part of its output domain" do
                    assert_raises(ArgumentError) do
                        task_m.new(setpoint: Hash[z: 10, x: 20])
                    end
                end
                it "raises ArgumentError if a field is not set that is part of its output domain" do
                    assert_raises(ArgumentError) do
                        task_m.new(setpoint: Hash[])
                    end
                end
                it "accepts a plain numeric value if the domain contains only one axis" do
                    plan.add(task = task_m.new(setpoint: 10))
                    assert_equal Hash[z: 10], task.arguments[:setpoint]
                end
                it "raises ArgumentError if given a plain numeric value and the domain contains more than one axis" do
                    assert_raises(ArgumentError) do
                        task_m = ConstantSetpointGenerator.for { WorldPos(:x, :y) }
                        task_m.new(setpoint: 10)
                    end
                end
            end
            it "generates the expected setpoint command with Time.now as time" do
                reference_time = Time.now
                flexmock(Time).should_receive(:now).and_return { reference_time }
                task = stub_deploy_and_start(task_m.with_arguments(setpoint: setpoint))
                sample = assert_has_one_new_sample(task.out_port)
                out = self.out.dup
                out.time = reference_time
                assert_equal out, sample
            end
        end
    end
end
