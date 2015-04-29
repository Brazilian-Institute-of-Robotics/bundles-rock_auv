require "rock_auv/models/services/control/element_model"
require "rock_auv/models/services/control/dsl"

module RockAUV
    module Services
        module Control
            Element = ElementModel.new
            WorldPos      = Element.new_submodel
            WorldVel      = Element.new_submodel
            AlignedPos    = Element.new_submodel
            AlignedVel    = Element.new_submodel
            AlignedEffort = Element.new_submodel
            BodyPos       = Element.new_submodel
            BodyVel       = Element.new_submodel
            BodyEffort    = Element.new_submodel

            module Element
                # @api private
                #
                # Helper method for {Controller.for} and {ControlledSystem.for}
                def self.for(root, domain, data_service_mappings, &block)
                    if !domain
                        if !block
                            raise ArgumentError, "domain neither given as argument, nor as a block"
                        end
                        domain = DSL.eval(&block)
                    end

                    root.each_submodel do |m|
                        if m.domain == domain
                            return m
                        end
                    end

                    result = root.new_submodel
                    result.domain = domain
                    domain.each do |reference, quantity, _|
                        if base_data_service = data_service_mappings[reference][quantity]
                            result.provides base_data_service
                        else
                            raise ArgumentError, "invalid reference/quantity pair #{reference}:#{quantity}"
                        end
                    end
                    result
                end
            end
        end
    end
end

