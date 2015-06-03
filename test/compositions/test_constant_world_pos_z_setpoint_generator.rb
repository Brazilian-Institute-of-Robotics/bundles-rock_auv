require 'models/compositions/constant_world_pos_z_setpoint_generator'

module RockAUV
    module Compositions
        describe ConstantWorldPosZSetpointGenerator do
            attr_reader :setpoint, :out

            before do
                @setpoint = 30
                @out = Types.base.LinearAngular6DCommand.new(
                    time: Time.at(0),
                    linear: Eigen::Vector3.new(Base.unset, Base.unset, setpoint),
                    angular: Eigen::Vector3.new(Base.unset, Base.unset, Base.unset))
            end

            it "generates the expected setpoint command with Time.now as time" do
                reference_time = Time.now
                flexmock(Time).should_receive(:now).and_return { reference_time }
                task = stub_deploy_and_start(ConstantWorldPosZSetpointGenerator.with_arguments(setpoint: setpoint))
                sample = assert_has_one_new_sample(task.out_port)
                out = self.out.dup
                out.time = reference_time
                assert_equal out, sample
            end
        end
    end
end
