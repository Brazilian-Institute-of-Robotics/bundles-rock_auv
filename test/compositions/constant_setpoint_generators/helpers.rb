module RockAUV
    module Compositions
        module ConstantSetpointGenerators
            def self.setup_common_test(test_klass, setpoint, *setpoint_fields)
                test_klass.class_eval do
                    it "generates the expected setpoint command with Time.now as time" do
                        out = Types.base.LinearAngular6DCommand.new(
                            time: Time.at(0),
                            linear: Eigen::Vector3.new(Base.unset, Base.unset, Base.unset),
                            angular: Eigen::Vector3.new(Base.unset, Base.unset, Base.unset))
                        setpoint_fields.each_slice(3) do |setpoint_field_name, setpoint_field_coordinate, setpoint_field_value|
                            out.send(setpoint_field_name).send("#{setpoint_field_coordinate}=", setpoint_field_value)
                        end

                        reference_time = Time.now
                        flexmock(Time).should_receive(:now).and_return { reference_time }
                        task = syskit_stub_deploy_configure_and_start(test_klass.desc.with_arguments(setpoint: setpoint))
                        sample = assert_has_one_new_sample(task.out_port)
                        out.time = reference_time
                        assert_equal out, sample
                    end
                end
            end
        end
    end
end

