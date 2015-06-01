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
                # You usually should not access this directly, but use {get}
                #
                # @return [Integer]
                attr_reader :encoded

                # Representation of which parts of the domain would be
                # influenced by a controller that generates commands in self
                attr_reader :conflicts

                # Creates a new domain from an encoded value
                def self.from_raw(encoded, conflicts = nil)
                    d = Domain.new
                    d.raw_set(encoded, conflicts)
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
                    @encoded = 0
                    if !args.empty?
                        if args.size != 3
                            raise ArgumentError, "expected no arguments or 3, got #{args.size}"
                        end
                        raw_set(Domain.encode(*args))
                    end
                end

                # @api private
                #
                # Sets this domain's values based on raw encoded values
                def raw_set(encoded, conflicts = nil)
                    @encoded = encoded
                    if !conflicts
                        conflicts = 0
                        e, idx = encoded, 0
                        while e != 0
                            if e & 1 == 1
                                conflicts |= CONFLICTS_MATRIX[idx]
                            end
                            e = e >> 1
                            idx += 1
                        end
                    end
                    @conflicts = conflicts
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
                def compatible_with?(domain)
                    (conflicts & domain.encoded) == 0
                end

                # Merges two control domains
                #
                # @param [Domain] domain the domain that should be merged with
                #   self
                # @return [Domain] the merged domain
                # @raise ArgumentError if self and domain control the same
                #   reference/quantity/axis
                def |(domain)
                    if !compatible_with?(domain)
                        raise IncompatibleDomains, "#{self} and #{domain} are incompatible"
                    end

                    Domain.from_raw(encoded | domain.encoded, conflicts | domain.conflicts)
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

                def hash; encoded.hash end
                def eql?(p); encoded.eql?(p.encoded) end
                def ==(p); encoded == p.encoded end
                def to_s
                    SHIFTS.map do |(reference,domain),shift|
                        encoded_axis = (encoded >> shift) & Axis::MASK
                        if encoded_axis != 0
                            reference.to_s.capitalize  +
                                domain.to_s.capitalize +
                                "(#{Axis.from_raw(encoded >> shift)})"
                        end
                    end.compact.join("|")
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

                # @api private
                #
                # Helper to build the CONFLICTS list
                def self.conflict_merge(*specs)
                    encoded = specs.each_slice(2).inject(0) do |e, (reference, axes)|
                        QUANTITIES_BY_REFERENCE[reference].each do |q|
                            e |= (axes.encoded << Domain.shift_for(reference, q))
                        end
                        e
                    end
                    encoded
                end

                # @api private
                #
                # Builds a matrix that allows to compute conflicts between
                # control domains
                def self.build_conflict_matrix(conflict_hash)
                    result = Array.new(SHIFTS.size * 6, 0)
                    conflict_hash.each do |if_set, conflicts|
                        r, axes = *if_set

                        axes.each do |a|
                            shifts = QUANTITIES_BY_REFERENCE[r].map do |q|
                                shift_for(r, q) + Axis.shift_for(a)
                            end
                            conflicts = shifts.inject(conflicts) do |c, s|
                                c | (1 << s)
                            end
                            QUANTITIES_BY_REFERENCE[r].each do |q|
                                idx = shift_for(r, q) + Axis.shift_for(a)
                                result[idx] = (1 << idx) | conflicts
                            end
                        end
                    end
                    result
                end

                CONFLICTS = Hash[
                    [:world, Axis.x! | Axis.y!] => conflict_merge(
                        :aligned, Axis.x! | Axis.y!,
                        :body, Axis.x! | Axis.y! | Axis.z!),
                    [:world, Axis.z!] => conflict_merge(
                        :aligned, Axis.z!,
                        :body, Axis.x! | Axis.y! | Axis.z!),
                    [:world, Axis.yaw!] => conflict_merge(
                        :aligned, Axis.yaw!,
                        :body, Axis.yaw! | Axis.pitch! | Axis.roll!),
                    [:world, Axis.pitch! | Axis.roll!] => conflict_merge(
                        :aligned, Axis.pitch! | Axis.roll!,
                        :body, Axis.yaw! | Axis.pitch! | Axis.roll!),
                    [:aligned, Axis.x! | Axis.y!] => conflict_merge(
                        :world, Axis.x! | Axis.y!,
                        :body, Axis.x! | Axis.y! | Axis.z!),
                    [:aligned, Axis.z!] => conflict_merge(
                        :world, Axis.z!,
                        :body, Axis.x! | Axis.y! | Axis.z!),
                    [:aligned, Axis.yaw!] => conflict_merge(
                        :world, Axis.yaw!,
                        :body, Axis.yaw! | Axis.pitch! | Axis.roll!),
                    [:aligned, Axis.pitch! | Axis.roll!] => conflict_merge(
                        :world, Axis.pitch! | Axis.roll!,
                        :body, Axis.yaw! | Axis.pitch! | Axis.roll!),
                    [:body, Axis.x! | Axis.y! | Axis.z!] => conflict_merge(
                        :world, Axis.x! | Axis.y! | Axis.z!,
                        :body, Axis.x! | Axis.y! | Axis.z!),
                ]
                CONFLICTS_MATRIX = build_conflict_matrix(CONFLICTS)

            end
        end
    end
end

