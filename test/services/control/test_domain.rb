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
                end

                describe 'conflict_merge' do
                    it "builds an encoded merge of all the provided axis for all quantities from the given reference" do
                        result = Domain.conflict_merge(
                            :world, Axis.x! | Axis.y!,
                            :body, Axis.roll!)
                        
                        expected = 
                            (Axis.x! | Axis.y!).encoded << Domain.shift_for(:world, :pos) |
                            (Axis.x! | Axis.y!).encoded << Domain.shift_for(:world, :vel) |
                            (Axis.x! | Axis.y!).encoded << Domain.shift_for(:world, :effort) |
                            Axis.roll!.encoded          << Domain.shift_for(:body, :pos) |
                            Axis.roll!.encoded          << Domain.shift_for(:body, :vel) |
                            Axis.roll!.encoded          << Domain.shift_for(:body, :effort) |
                            Axis.roll!.encoded          << Domain.shift_for(:body, :thrust)
                        
                        assert_equal expected, result, "expected #{Domain.from_raw(expected, 0)}, got #{Domain.from_raw(result, 0)}"
                    end
                end

                describe "build_conflict_matrix" do
                    it "builds the mapping from a point in the domain to the domain space that is in conflict" do
                        conflicts = Hash[
                            [:aligned, Axis.x! | Axis.roll!] => Domain.conflict_merge(
                                :aligned, Axis.x! | Axis.y!,
                                :body, Axis.x! | Axis.y! | Axis.z!)]
                        conflict_matrix = Domain.build_conflict_matrix(conflicts)

                        # :world, :pos, :x
                        expected_conflicts = 
                            Domain.encode(:aligned, :pos, Axis.x! | Axis.y!) |
                            Domain.encode(:aligned, :vel, Axis.x! | Axis.y!) |
                            Domain.encode(:aligned, :effort, Axis.x! | Axis.y!) |
                            Domain.encode(:body, :pos, Axis.x! | Axis.y! | Axis.z!) |
                            Domain.encode(:body, :vel, Axis.x! | Axis.y! | Axis.z!) |
                            Domain.encode(:body, :effort, Axis.x! | Axis.y! | Axis.z!) |
                            Domain.encode(:body, :thrust, Axis.x! | Axis.y! | Axis.z!)

                        expected_aligned_x =
                            Domain.encode(:aligned, :pos, :x) |
                            Domain.encode(:aligned, :vel, :x) |
                            Domain.encode(:aligned, :effort, :x) |
                            expected_conflicts

                        expected_aligned_roll =
                            Domain.encode(:aligned, :pos, :roll) |
                            Domain.encode(:aligned, :vel, :roll) |
                            Domain.encode(:aligned, :effort, :roll) |
                            expected_conflicts

                        expected = [0] * Domain::SHIFTS.size * 6
                        expected[3 * 6] = expected_aligned_x
                        expected[4 * 6] = expected_aligned_x
                        expected[5 * 6] = expected_aligned_x
                        expected[3 * 6 + 5] = expected_aligned_roll
                        expected[4 * 6 + 5] = expected_aligned_roll
                        expected[5 * 6 + 5] = expected_aligned_roll
                        assert_equal expected, conflict_matrix
                    end
                end

                describe "conflicts_with?" do
                    it "returns true if any of the domain parts conflict" do
                        matrix = Array.new
                        matrix[3] = 0b00101
                        d0 = Domain.from_raw(0b101)
                        d1 = Domain.from_raw(0b00100)
                        assert d0.conflicts_with?(d1, matrix: matrix)
                    end

                    it "returns false if none of the domain parts conflict" do
                        matrix = Array.new
                        matrix[3] = 0b00101
                        d0 = Domain.from_raw(0b1001)
                        d1 = Domain.from_raw(0b00100)
                        assert d0.conflicts_with?(d1, matrix: matrix)
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
                    it "raises IncompatibleDomains if the two domains are controlling same part of the control space" do
                        assert_raises(Domain::IncompatibleDomains) do
                            Domain.new(:world, :pos, Axis.x!) |
                                Domain.new(:world, :pos, Axis.x!)
                        end
                    end
                    it "can recognize that two parts of the domain are compatible" do
                        Domain.new(:world, :pos, Axis.x!) |
                            Domain.new(:aligned, :vel, Axis.z!)
                    end
                    it "raises IncompatibleDomains if the merged domain controls parts that are already controlled by self because of cascading" do
                        assert_raises(Domain::IncompatibleDomains) do
                            Domain.new(:world, :pos, Axis.x!) |
                                Domain.new(:body, :vel, Axis.z!)
                        end
                    end
                end
            end
        end
    end
end

