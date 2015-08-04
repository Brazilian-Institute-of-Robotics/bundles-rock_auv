require 'rock/models/compositions/constant_generator'
require 'rock_auv/models/compositions/control/generator'

module RockAUV
    module Compositions
        module Control
            describe Generator do
                describe "#producer_elements" do
                    attr_reader :cascade, :producer, :aligned_pos_srv, :aligned_vel_srv, :task_m
                    before do
                        @aligned_pos_srv = Services::Controller.for { AlignedPos(:pitch,:roll)  }
                        @aligned_vel_srv = Services::Controller.for { AlignedVel(:x,:yaw) }
                        @task_m = Syskit::TaskContext.new_submodel do
                            output_port 'cmd_out_aligned_pos', '/base/LinearAngular6DCommand'
                            output_port 'cmd_out_aligned_vel', '/base/LinearAngular6DCommand'
                        end
                        task_m.provides aligned_pos_srv, as: 'aligned_pos'
                        task_m.provides aligned_vel_srv, as: 'aligned_vel'

                        @cascade = Syskit::Composition.new_submodel
                        @producer = cascade.add(task_m, as: 'test')
                    end

                    it "splits the producer across its domains" do
                        result = Generator.producer_elements('test', producer)
                        
                        axis = Services::Control::Axis
                        expected = [
                            Generator::Producer.new('test', [:aligned,:pos], axis.pitch! | axis.roll!, cascade.test_child.aligned_pos_srv.as(aligned_pos_srv), "aligned_pos_pitch_roll"),
                            Generator::Producer.new('test', [:aligned,:vel], axis.x! | axis.yaw!, cascade.test_child.aligned_vel_srv.as(aligned_vel_srv), "aligned_vel_x_yaw")]

                        assert_equal expected.to_set, result.to_set
                    end
                end
            end
        end
    end
end

