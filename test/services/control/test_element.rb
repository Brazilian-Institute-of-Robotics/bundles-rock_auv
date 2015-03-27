require 'models/services/control/element'

module RockAUV
    module Services
        module Control
            describe Element do
                describe 'for' do
                    attr_reader :domain, :service_mappings

                    before do
                        @service_mappings =
                            Hash[:world => Hash[
                                    :pos => WorldPos,
                                    :vel => WorldVel],
                                :aligned => Hash[
                                    :pos => AlignedPos,
                                    :vel => AlignedVel,
                                    :effort => AlignedEffort],
                                :body => Hash[
                                    :effort => BodyEffort]]

                        @domain = Domain.new(:world, :pos, :x) |
                            Domain.new(:body, :effort, :roll)
                    end

                    it "creates a new dataservice submodel providing the domain-specific services" do
                        srv = Element.for(domain, service_mappings)
                        assert srv.provides?(WorldPos)
                        assert srv.provides?(BodyEffort)
                    end
                    it "stores the domain in its #domain attribute" do
                        srv = Element.for(domain, service_mappings)
                        assert_equal domain, srv.domain
                    end
                    it "returns the same submodel for the same domain description" do
                        srv = Element.for(domain, service_mappings)
                        assert_same srv, Element.for(domain, service_mappings)
                    end
                end
            end
        end
    end
end
