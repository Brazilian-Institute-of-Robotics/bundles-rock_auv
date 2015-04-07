require 'models/services/controlled_system'

module RockAUV
    module Services
        describe ControlledSystem do
            describe "for" do
                attr_reader :domain
                before do
                    @domain = Control::DSL.eval do
                        AlignedPos(:pitch,:roll) | BodyEffort(:x, :y, :z) 
                    end
                end

                it "evaluates the provided block to build the domain" do
                    srv1 = ControlledSystem.for(domain)
                    srv2 = ControlledSystem.for do
                        AlignedPos(:pitch,:roll) | BodyEffort(:x, :y, :z) 
                    end
                    assert_same srv1, srv2
                end
                it "sets the service's domain variable to the provided domain" do
                    srv = ControlledSystem.for(domain)
                    assert_equal domain, srv.domain
                end
                it "creates a combination of service models that represents the combination of the control domain" do
                    srv = ControlledSystem.for(domain)
                    expected = [srv,
                        BodyEffortControlledSystem,
                        AlignedPosControlledSystem,
                        ControlledSystem,
                        Rock::Services::ControlledSystem,
                        Control::BodyEffort,
                        Control::AlignedPos,
                        Control::Element,
                        Syskit::DataService]

                    assert_equal expected, srv.each_fullfilled_model.to_a
                end
                it "returns the same service for the same domain" do
                    srv1 = ControlledSystem.for(domain)
                    srv2 = ControlledSystem.for(domain)
                    assert_same srv1, srv2
                end
                it "does create a new service even if a controller with the same domain has already been created" do
                    srv1 = Controller.for(domain)
                    srv2 = ControlledSystem.for(domain)
                    refute_same srv1, srv2
                end
            end
        end
    end
end
