require 'rock_auv/models/services/control/axis'

module RockAUV
    module Services
        module Control
            describe Axis do
                attr_reader :axis
                before do
                    @axis = Axis.new
                end


                def assert_axes_set(axis, *expected)
                    all = Axis::SHIFTS.keys
                    expected = expected.to_set
                    all.each do |axis_name|
                        if expected.include?(axis_name)
                            assert axis.get(axis_name), "expected #{expected.map(&:to_s).join(", ")}, got #{axis}"
                        else
                            assert !axis.get(axis_name), "expected #{expected.map(&:to_s).join(", ")}, got #{axis}"
                        end
                    end
                end

                describe ".shift_for" do
                    it "raises InvalidAxis if an invalid axis is given" do
                        assert_raises(Axis::InvalidAxis) do
                            Axis.shift_for(:does_not_exist)
                        end
                    end
                    it "returns the shift of the given axis" do
                        assert_equal 2, Axis.shift_for(:z)
                    end
                end

                describe "#only?" do
                    it "returns false if the axis is not controlled" do
                        assert !axis.only?(:x)
                    end
                    it "returns false if more than the specified axis is controlled" do
                        assert !axis.x!.y!.only?(:x)
                    end
                    it "returns true if only the specified axis is controlled" do
                        assert axis.x!.only?(:x)
                    end
                end

                describe "#empty?" do
                    it "returns true if no axes are set" do
                        assert axis.empty?
                    end
                    it "returns false if at least one axis is set" do
                        axis.x!
                        assert !axis.empty?
                        axis.pitch!
                        assert !axis.empty?
                    end
                end

                describe "#|" do
                    it "allows to merge to sets of axis" do
                        merged = (Axis.new.x! | Axis.new.roll!)
                        assert_axes_set(merged, :x, :roll)
                    end
                end

                describe "#&" do
                    it "allows to compute the intersection of two sets of axis" do
                        merged = (Axis.new.x!.y!.pitch! & Axis.new.x!.pitch!.roll!)
                        assert_axes_set(merged, :x, :pitch)
                    end
                end

                describe "test methods" do
                    it "returns false if x is not set" do
                        assert !axis.x?
                    end
                    it "returns false if y is not set" do
                        assert !axis.y?
                    end
                    it "returns false if z is not set" do
                        assert !axis.z?
                    end
                    it "returns false if yaw is not set" do
                        assert !axis.yaw?
                    end
                    it "returns false if pitch is not set" do
                        assert !axis.pitch?
                    end
                    it "returns false if roll is not set" do
                        assert !axis.roll?
                    end

                    it "returns true if x is set" do
                        assert axis.x!.x?
                    end
                    it "returns true if y is set" do
                        assert axis.y!.y?
                    end
                    it "returns true if z is set" do
                        assert axis.z!.z?
                    end
                    it "returns true if yaw is set" do
                        assert axis.yaw!.yaw?
                    end
                    it "returns true if pitch is set" do
                        assert axis.pitch!.pitch?
                    end
                    it "returns true if roll is set" do
                        assert axis.roll!.roll?
                    end
                end

                describe "setting methods" do
                    it "allows to set the X axis only" do
                        assert axis.x!.only?(:x)
                    end
                    it "allows to set the Y axis only" do
                        assert axis.y!.only?(:y)
                    end
                    it "allows to set the Z axis only" do
                        assert axis.z!.only?(:z)
                    end
                    it "allows to set the Yaw axis only" do
                        assert axis.yaw!.only?(:yaw)
                    end
                    it "allows to set the Pitch axis only" do
                        assert axis.pitch!.only?(:pitch)
                    end
                    it "allows to set the Roll axis only" do
                        assert axis.roll!.only?(:roll)
                    end
                end
            end
        end
    end
end

