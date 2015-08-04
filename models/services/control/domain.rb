require 'rock_auv/models/services/control/axis'

module RockAUV
    module Services
        module Control
            # @!macro reference_and_quantity
            #   @param [Symbol] reference the reference frame, as either :world,
            #     :aligned or :body
            #   @param [Symbol] quantity the controlled quantity, as either :pos,
            #     :vel or :effort

            # Representation of a control domain
            #
            # For each:
            # 
            # reference:: the control reference frame (:world, :aligned or
            #             :body)
            # quantity:: the controlled quantity (:pose, :vel or :effort)
            #
            # It stores the set of control axis that are being controlled, and
            # provides access to it via an {Axis} object
            #
            class Domain
                class IncompatibleDomains < ArgumentError; end

                # The encoded domain
                #
                # You usually should not access this directly, but use {#get}
                #
                # @return [Integer]
                attr_reader :encoded

                # Creates a new domain from an encoded value
                def self.from_raw(encoded)
                    d = Domain.new
                    d.raw_set(encoded)
                    d
                end

                def self.encode(reference, domain, axes)
                    if !axes.respond_to?(:encoded)
                        axes = Axis.new.set(axes)
                    end
                    shift = Domain.shift_for(reference, domain)
                    axes.encoded << shift
                end

                # @overload Domain.new
                #   creates a new empty domain
                # @overload Domain.new(reference, quantity, axis)
                #   creates a new domain that controls a single axis
                #   @param [Symbol] reference the control reference frame. One of
                #     :world, :aligned or :body
                #   @param [Symbol] quantity the quantity being controlled. One of
                #     :pos, :vel or :effort
                #   @param [Axis,Symbol] axis the axis being controlled. One of
                #     :x, :y, :z, :yaw, :pitch, :roll
                def initialize(*args)
                    encoded = 0
                    if !args.empty?
                        if args.size != 3
                            raise ArgumentError, "expected no arguments or 3, got #{args.size}"
                        end
                        encoded = Domain.encode(*args)
                    end
                    raw_set(encoded)
                end

                # @api private
                #
                # Sets this domain's values based on raw encoded values
                def raw_set(encoded)
                    @encoded = encoded
                end

                # Returns true if this control domain controls nothing
                def empty?
                    encoded == 0
                end

                # @api private
                #
                # Helper method to validate passed reference and quantity values
                def self.shift_for(reference, quantity)
                    shift = SHIFTS[[reference, quantity]]
                    if !shift
                        if !REFERENCE_NAMES.include?(reference)
                            raise InvalidReference, "invalid reference #{reference}, known references are :#{REFERENCE_NAMES.map(&:to_s).join(", :")}"
                        elsif !QUANTITY_NAMES.include?(quantity)
                            raise InvalidQuantity, "invalid quantity #{quantity}, known quantities are :#{QUANTITY_NAMES.map(&:to_s).join(", :")}"
                        else
                            raise InvalidReferenceQuantityCombination, "invalid combination #{reference},#{quantity}, acceptable combinations are #{SHIFTS.keys.map(&:inspect).join(", ")}"
                        end
                    end
                    shift
                end

                # Returns which axes are being controlled within this domain for
                # the given reference and controlled quantity
                #
                # @!macro reference_and_quantity
                # @return [Axis]
                def get(reference, quantity)
                    shift = Domain.shift_for(reference, quantity)
                    encoded_axis = (encoded >> shift) & Axis::MASK
                    Axis.from_raw(encoded_axis)
                end

                # Verifies that the given control domain and this one do not
                # overlap
                def intersects_with?(domain)
                    (encoded & domain.encoded) != 0
                end

                # Merges two control domains
                #
                # @param [Domain] domain the domain that should be merged with
                #   self
                # @return [Domain] the merged domain
                def |(domain)
                    Domain.from_raw(encoded | domain.encoded)
                end

                # Returns the intersection of two domains
                #
                # @param [Domain] domain the domain that should be intersected with
                #   self
                # @return [Domain] the intersection
                def &(domain)
                    Domain.from_raw(encoded & domain.encoded)
                end

                # Enumerates all parts of the control domain that are actually
                # controlled
                #
                # @yieldparam [Symbol] reference the reference part
                #   (:world,:aligned,:body)
                # @yieldparam [Symbol] quantity the quantity part
                #   (:pos,:vel,:effort)
                # @yieldparam [Axis] axis the axes being controlled
                # @return [void]
                def each
                    return enum_for(__method__) if !block_given?
                    SHIFTS.each_key do |reference, quantity|
                        axis = get(reference, quantity)
                        if !axis.empty?
                            yield(reference, quantity, axis)
                        end
                    end
                    nil
                end

                # Exception raised when a {#simple_domain} was expected but the
                # domain is not simple
                class ComplexDomainError < ArgumentError; end

                # Verifies that this is a simple domain and returns it
                #
                # @raise ArgumentError if the domain has one more
                #   reference/quantity
                # @return [(Symbol,Symbol,Axis)]
                def simple_domain
                    ret = nil
                    each do |r, q, a|
                        if ret
                            raise ComplexDomainError, "#{self} is not a simple domain"
                        else
                            ret = [r, q, a]
                        end
                    end
                    if ret
                        return *ret
                    else
                        return nil, nil, Axis.new
                    end
                end

                def hash; encoded.hash end
                def eql?(p); encoded.eql?(p.encoded) end
                def ==(p); encoded == p.encoded end
                def to_s
                    this = SHIFTS.map do |(reference,domain),shift|
                        encoded_axis = (encoded >> shift) & Axis::MASK
                        if encoded_axis != 0
                            reference.to_s.capitalize  +
                                domain.to_s.capitalize +
                                "(#{Axis.from_raw(encoded >> shift)})"
                        end
                    end.compact.join("|")
                end

                def inspect
                    "RockAUV::Services::Control::Domain { #{to_s} }"
                end

                SHIFTS = Hash[
                    [:world, :pos]      => 0 * 6,
                    [:world, :vel]      => 1 * 6,
                    [:world, :effort]   => 2 * 6,
                    [:aligned, :pos]    => 3 * 6,
                    [:aligned, :vel]    => 4 * 6,
                    [:aligned, :effort] => 5 * 6,
                    [:body, :pos]       => 6 * 6,
                    [:body, :vel]       => 7 * 6,
                    [:body, :effort]    => 8 * 6,
                    [:body, :thrust]    => 9 * 6]

                class InvalidReferenceQuantityCombination < ArgumentError; end
                class InvalidReference < ArgumentError; end
                REFERENCE_NAMES = SHIFTS.keys.map(&:first).uniq
                QUANTITY_NAMES  = SHIFTS.keys.map(&:last).sort.uniq
                class InvalidQuantity < ArgumentError; end
                QUANTITIES_BY_REFERENCE = Hash.new
                SHIFTS.each_key do |r, q|
                    (QUANTITIES_BY_REFERENCE[r] ||= Array.new) << q
                end
            end

            def self.Domain(&block)
                DSL.eval(&block)
            end
        end
    end
end

