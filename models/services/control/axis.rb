module RockAUV
    module Services
        module Control
            # Representation of a set of axis in {x, y, z, yaw, pitch, roll}
            #
            # It is used to build a control {Domain}
            class Axis
                attr_accessor :encoded

                SHIFTS = Hash[
                    :x => 0,
                    :y => 1,
                    :z => 2,
                    :yaw => 3,
                    :pitch => 4,
                    :roll => 5]
                MASK = (1 << 6) - 1

                class InvalidAxis < ArgumentError; end

                def hash; encoded end
                def eql?(other); encoded == other.encoded end
                def ==(other)
                    eql?(other)
                end

                def self.shift_for(axis)
                    if s = SHIFTS[axis]
                        s
                    else
                        raise InvalidAxis, "unknown axis name #{axis}, expected #{SHIFTS.keys.map(&:inspect).join(", ")}"
                    end
                end

                # Initializes an {Axis} structure directly from its encoded value
                def self.from_raw(encoded)
                    p =  new
                    p.encoded = encoded
                    p
                end

                # Initializes an {Axis} structure based on a set of named parameters
                def initialize(*parameters)
                    @encoded = 0
                    parameters.each { |name| set(name.to_sym) }
                end

                # Declares that the x axis is being controlled
                def x!; set(:x) end
                # Tests whether x is being controlled
                # @return [Boolean]
                def x?; get(:x) end
                # Declares that the y axis is being controlled
                def y!; set(:y) end
                # Tests whether y is being controlled
                # @return [Boolean]
                def y?; get(:y) end
                # Declares that the z axis is being controlled
                def z!; set(:z) end
                # Tests whether z is being controlled
                # @return [Boolean]
                def z?; get(:z) end
                # Declares that the yaw axis is being controlled
                def yaw!; set(:yaw) end
                # Tests whether yaw is being controlled
                # @return [Boolean]
                def yaw?; get(:yaw) end
                # Declares that the pitch axis is being controlled
                def pitch!; set(:pitch) end
                # Tests whether pitch is being controlled
                # @return [Boolean]
                def pitch?; get(:pitch) end
                # Declares that the roll axis is being controlled
                def roll!; set(:roll) end
                # Tests whether roll is being controlled
                # @return [Boolean]
                def roll?; get(:roll) end

                # Declares that one of the axis is being controlled
                # @param [Symbol] parameter
                def set(axis)
                    @encoded |= (1 << SHIFTS[axis.to_sym])
                    self
                end

                # Returns the encoded value masked to extract the given axis
                def raw_get(axis)
                    encoded & (1 << SHIFTS[axis.to_sym])
                end

                # Tests whether one of the axis is being controlled
                # @param [Symbol] parameter
                # @return [Boolean]
                def get(axis)
                    raw_get(axis) != 0
                end

                # Tests whether some axis are set
                def empty?
                    encoded == 0
                end

                def only?(axis)
                    value = raw_get(axis)
                    (value == encoded) && (value != 0)
                end

                def |(a)
                    self.class.from_raw(encoded | a.encoded)
                end

                def &(a)
                    self.class.from_raw(encoded & a.encoded)
                end

                def ==(value)
                    encoded == value.encoded
                end

                def compact_name
                    SHIFTS.map { |name, shift| name.to_s if (encoded & (1 << shift) != 0) }.
                        compact.join("")
                end

                def to_s
                    SHIFTS.map { |name, shift| name.to_s if (encoded & (1 << shift) != 0) }.
                        compact.join(",")
                end

                def self.x!; Axis.new.x! end
                def self.y!; Axis.new.y! end
                def self.z!; Axis.new.z! end
                def self.yaw!; Axis.new.yaw! end
                def self.pitch!; Axis.new.pitch! end
                def self.roll!; Axis.new.roll! end

                def each
                    return enum_for(__method__) if !block_given?
                    SHIFTS.each do |name, s|
                        if ((encoded >> s) & 1) == 1
                            yield(name)
                        end
                    end
                end
            end
        end
    end
end
