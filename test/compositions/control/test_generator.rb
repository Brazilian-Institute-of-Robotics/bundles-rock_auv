require 'rock_auv/models/compositions/control/generator'

module RockAUV
    module Compositions
        module Control
            describe Generator do
                describe "#producer_elements" do
                    attr_reader :producer
                    before do
                        service = Services::Controller.for do
                            AlignedPos(:pitch,:roll) | AlignedVel(:x,:yaw)
                        end
                        @producer = Rock::Compositions::ConstantGenerator.for(service)
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

