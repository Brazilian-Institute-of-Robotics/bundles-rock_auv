module RockAUV
    module Compositions
        module Control
            # Expresses how an output in a source domain can be converted to an
            # input in another domain
            class Rule
                # The name of the rule. It must be unique, as it is going to be used
                # as the child name in the generated composition(s)
                #
                # @return [String]
                attr_reader :name
                # The source domain
                # @return [(Symbol,Symbol)] the names of reference and quantity
                attr_reader :source_domain
                # The target domain
                # @return [(Symbol,Symbol)] the names of reference and quantity
                attr_reader :target_domain
                # Set of modification rules on the axis
                # @return [{Integer=>Integer}] the source axis are matched against
                #   the given bitmasks. If matching, the target bitmasks are
                #   applied on the generated control domain
                attr_reader :axis
                # The component that will handle the convertion
                attr_reader :convertion_component

                def initialize(name, source_domain, target_domain, axis, convertion_component)
                    @name, @source_domain, @target_domain, @axis, @convertion_component =
                        name, source_domain, target_domain, axis, convertion_component
                end
            end
        end
    end
end


