require 'models/services/controller'

module RockAUV
    module Services
        describe Controller do
            describe "for" do
                attr_reader :domain
                before do
                    @domain = Control::DSL.eval do
                        AlignedPos(:pitch,:roll) | BodyEffort(:x, :y, :z) 
                    end
                end

                it "evaluates the provided block to build the domain" do
                    srv1 = Controller.for(domain)
                    srv2 = Controller.for do
                        AlignedPos(:pitch,:roll) | BodyEffort(:x, :y, :z) 
                    end
                    assert_same srv1, srv2
                end
                it "sets the service's domain variable to the provided domain" do
                    srv = Controller.for(domain)
                    assert_equal domain, srv.domain
                end
                it "creates a combination of service models that represents the combination of the control domain" do
                    srv = Controller.for(domain)
                    expected = [srv,
                        BodyEffortController,
                        AlignedPosController,
                        Controller,
                        Rock::Services::Controller,
                        Control::BodyEffort,
                        Control::AlignedPos,
                        Control::Element,
                        Syskit::DataService]

                    assert_equal expected, srv.each_fullfilled_model.to_a
                end
                it "returns the same service for the same domain" do
                    srv1 = Controller.for(domain)
                    srv2 = Controller.for(domain)
                    assert_same srv1, srv2
                end
            end
        end
    end
end
