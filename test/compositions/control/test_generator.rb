require 'rock/models/compositions/constant_generator'
require 'rock_auv/models/compositions/control/generator'

module RockAUV
    module Compositions
        module Control
            describe Generator do
                describe "#producer_elements" do
                    attr_reader :producer
                    before do
                        aligned_pos_srv = Services::Controller.for { AlignedPos(:pitch,:roll)  }
                        aligned_vel_srv = Services::Controller.for { AlignedVel(:x,:yaw) }
                        cascade = Syskit::Composition.new_submodel
                        @producer = cascade.add(Rock::Compositions::ConstantGenerator.for(service), as: 'test')
                    end

                    it "splits the producer across its domains" do
                        result = Generator.producer_elements('test', producer)
                        
                        expected = [Services::Controller.for { AlignedPos(:pitch,:roll) },
                                    Services::Controller.for { AlignedVel(:x, :yaw) }]
                        assert_equal expected.to_set, result.map { |p| p.bound_service.model }.to_set
                    end
                end
            end
        end
    end
end

