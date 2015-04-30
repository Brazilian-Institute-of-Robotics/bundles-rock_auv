require 'models/compositions/constant_depth_generator'

module RockAUV
    module Compositions
        describe ConstantDepthGenerator do
            describe "#depth=" do
                it "sets the depth parameter" do
                    task = ConstantDepthGenerator.new
                    task.depth = 10
                    assert_equal 10, task.arguments[:depth]
                end
                it "sets the ConstantGenerator's values parameter" do
                    task = ConstantDepthGenerator.new
                    task.depth = 10

                    values = task.arguments[:values]
                    assert_equal ['out'], values.keys
                    cmd = values['out']
                    assert_kind_of Types.base.LinearAngular6DCommand, cmd
                    assert Base.unset?(cmd.linear.x)
                    assert Base.unset?(cmd.linear.y)
                    assert_equal 10, cmd.linear.z
                    assert Base.unset?(cmd.angular.x)
                    assert Base.unset?(cmd.angular.y)
                    assert Base.unset?(cmd.angular.z)
                end
            end
            it "generates the expected depth command" do
                generator = stub_deploy_and_start_composition(ConstantDepthGenerator.with_arguments(depth: 10))
                sample = assert_has_one_new_sample(generator.out_port)
                assert Base.unset?(sample.linear.x)
                assert Base.unset?(sample.linear.y)
                assert_equal 10, sample.linear.z
                assert Base.unset?(sample.angular.x)
                assert Base.unset?(sample.angular.y)
                assert Base.unset?(sample.angular.z)
            end
        end
    end
end
