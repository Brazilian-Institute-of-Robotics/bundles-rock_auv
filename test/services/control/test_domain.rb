require 'rock_auv/models/services/control/domain'

module RockAUV
    module Services
        module Control
            describe Domain do
                describe ".shift_for" do
                    it "raises InvalidReference if the provided reference does not exist" do
                        assert_raises(Domain::InvalidReference) do
                            Domain.shift_for(:foo, :pos)
                        end
                    end
                    it "raises InvalidQuantity if the provided quantity does not exist" do
                        assert_raises(Domain::InvalidQuantity) do
                            Domain.shift_for(:world, :foo)
                        end
                    end
                    it "raises InvalidReferenceQuantityCombination if the provided reference/quantity combination is not allowed" do
                        flexmock(:base, Domain::SHIFTS).should_receive(:[]).and_return(nil)
                        assert_raises(Domain::InvalidReferenceQuantityCombination) do
                            Domain.shift_for(:world, :vel)
                        end
                    end
                    it "returns the shift value for the given reference/quantity" do
                        assert_equal Domain::SHIFTS[[:world,:vel]],
                            Domain.shift_for(:world, :vel)
                    end
                end

                describe "#initialize" do
                    it "creates an empty domain if given no argument(s)" do
                        assert Domain.new.empty?
                    end
                    it "creates a domain with a single reference and quantity if given arguments" do
                        domain = Domain.new(:world, :vel, :x)
                        assert_equal Axis.x!, domain.get(:world, :vel)
                        
                    end
                    it 'raises ArgumentError if given neither 0 nor 3 arguments' do
                        assert_raises(ArgumentError) do
                            Domain.new(:world)
                        end
                    end
                end

                describe "intersects_with?" do
                    it "returns true if any of the domain parts are common" do
                        d0 = Domain.from_raw(0b00101)
                        d1 = Domain.from_raw(0b00100)
                        assert d0.intersects_with?(d1)
                    end

                    it "returns false if none of the domain parts are common" do
                        d0 = Domain.from_raw(0b1001)
                        d1 = Domain.from_raw(0b0010)
                        assert !d0.intersects_with?(d1)
                    end
                end

                describe "#|" do
                    it "merges domains" do
                        domain = Domain.new(:world, :pos, Axis.x!) |
                            Domain.new(:body, :vel, Axis.roll!)

                        assert_equal Axis.x!, domain.get(:world, :pos)
                        assert_equal Axis.roll!, domain.get(:body, :vel)
                    end
                    it "merges axis within the same parts of the domain" do
                        domain = Domain.new(:world, :pos, Axis.x!) |
                            Domain.new(:world, :pos, Axis.y!)

                        assert_equal (Axis.x! | Axis.y!), domain.get(:world, :pos)
                    end
                    it "is identity when merging with an empty domain" do
                        domain = Domain.new(:world, :pos, Axis.x!)
                        assert_equal domain, (domain | Domain.new)
                        assert_equal domain, (Domain.new | domain)
                    end
                end

                describe "#simple_domain" do
                    it "raises ArgumentError if the domain is not simple" do
                        domain = Domain.new(:world, :pos, Axis.x!) | Domain.new(:world, :vel, Axis.y!)
                        assert_raises(ArgumentError) do
                            domain.simple_domain
                        end
                    end
                    it "returns the reference, quantity and axis of a simple domain" do
                        domain = Domain.new(:world, :pos, Axis.x! | Axis.y!)
                        assert_equal [:world, :pos, Axis.x! | Axis.y!], domain.simple_domain
                    end
                end
            end
        end
    end
end

