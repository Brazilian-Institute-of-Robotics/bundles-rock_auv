using_task_library 'auv_control'
require 'rock_auv/models/compositions/control/rule'
require 'rock_auv/models/services/controller'
require 'rock_auv/models/services/controlled_system'

module RockAUV
    module Compositions
        module Control
            # @api private
            #
            # Algorithm that generates a submodel of Cascade based on a set of
            # producers
            #
            # This is the implementation of {ControlCascade.for}
            class Generator
                extend Logger::Root(self.name.to_s, Logger::INFO)

                Axis = Services::Control::Axis

                DEFAULT_THRUSTER_CONTROL_RULES = [
                    Rule.new("body_effort2thrust", [:body,:effort], [:body,:thrust],
                             Hash[],
                             OroGen::AuvControl::AccelerationController)
                ]

                Producer = Struct.new :name, :domain, :axis, :bound_service, :port_name do
                    def to_s
                        "#<Producer/#{domain[0]}/#{domain[1]}/#{axis} #{bound_service}>"
                    end
                end

                # Set of rules this generator should apply
                #
                # @return [Array<Rule>]
                attr_reader :rules

                def initialize(rules)
                    @rules = rules
                end

                def create(producers)
                    result = ControlCascade.new_submodel
                    producers = Hash(producers)

                    # Add the producers to the composition, so that we deal only with
                    # children of the composition
                    producers = add_producers_to_cascade(result, producers)

                    # Sort the producers by reference/quantity they generate
                    producers_by_domains = Hash.new
                    producers.each do |name, raw_producer|
                        resolved_producer = self.class.producer_elements(name, raw_producer)
                        resolved_producer.each do |p|
                            producers_by_domains[p.domain] ||= Array.new
                            producers_by_domains[p.domain] << p
                        end
                    end

                    # Apply the rules one by one, in order
                    rules.each do |rule|
                        if resolved_producers = producers_by_domains[rule.source_domain]
                            Generator.debug do
                                Generator.debug "applying #{resolved_producers.size} producers"
                                resolved_producers.each do |p|
                                    Generator.debug "  #{p}"
                                end
                                break
                            end
                            new_producer = self.class.apply_rule(result, rule, resolved_producers)
                            producers_by_domains[rule.target_domain] ||= Array.new
                            producers_by_domains[rule.target_domain] << new_producer
                        end
                    end

                    # Find the body-thrust controller
                    body_thrust_controllers = producers_by_domains[[:body,:thrust]]
                    if body_thrust_controllers.empty?
                        raise InvalidRules, "could not produce a body-thrust controller"
                    elsif body_thrust_controllers.size > 1
                        raise InvalidRules, "produced more than one body-thrust controller"
                    end
                    body_thrust_controllers.first.
                        bound_service.connect_to result.thrusters_child

                    result
                end

                def add_producers_to_cascade(cascade, producers)
                    result = Hash.new
                    producers.each do |name, p|
                        p = p.to_instance_requirements
                        result[name] = cascade.add p, as: name
                    end
                    result
                end

                # Enumerates the services of a given component model that are
                # relevant for production
                #
                # @param [String] name the name that should be used in the
                #   returned Producer objects
                # @param [Syskit::Model::CompositionChild] producer the producer
                #   component. It is the referenced to as the child of the
                #   generated cascade composition
                # @return [Array<Producer>]
                def self.producer_elements(name, producer)
                    services = producer.find_all_data_services_from_type(Services::Controller)
                    if services.empty?
                        raise ArgumentError, "#{producer} does not provide #{Services::Controller}"
                    end

                    services.flat_map do |srv|
                        # We want the actual service, not the service-as-Controller
                        srv = srv.as_real_model

                        # Here, 'srv' is a bound data service on a composition
                        # child. We want the real child model. Deference #model
                        # twice
                        srv.model.model.domain.each.map do |reference, quantity, axis|
                            base_srv = Services::Controller.for(Services::Control::Domain.new(reference, quantity, axis))
                            Producer.new(name, [reference,quantity], axis, srv.as(base_srv), "#{reference}_#{quantity}_#{axis.each.to_a.join("_")}")
                        end
                    end
                end

                # Applies a given rule on the Cascade submodel
                #
                # Given a rule and a set of producers, it adds the relevant children to
                # the composition model and inserts the convertion element the rule
                # refers to
                def self.apply_rule(composition_m, rule, producers)
                    new_axis = Axis.new

                    convertion_m = rule.convertion_component.specialize
                    in_reference, in_quantity = *rule.source_domain
                    producer_pairs = producers.map do |p|
                        new_axis |= p.axis
                        [p, convertion_m.require_dynamic_service(
                            "in_#{in_reference}_#{in_quantity}",
                            as: p.name,
                            port_name: p.port_name,
                            control_domain_srv: Services::ControlledSystem.for(Services::Control::Domain.new(*p.domain, p.axis)))]
                    end

                    reference, quantity = *rule.target_domain
                    output_srv = Services::Controller::REFERENCE_QUANTITY_TO_SERVICE_MAPPINGS[reference][quantity]
                    if !output_srv
                        raise NotImplementedError, "no controller service defined for #{reference} #{quantity}"
                    end

                    out_name = "#{reference}_#{quantity}_#{new_axis.compact_name}"
                    convertion_srv = convertion_m.require_dynamic_service(
                        "out_#{reference}_#{quantity}",
                        as: out_name,
                        control_domain_srv: Services::Controller.for(Services::Control::Domain.new(reference, quantity, new_axis)))

                    convertion_name = "#{in_reference}_#{in_quantity}2#{reference}_#{quantity}"
                    convertion_m = convertion_m.
                        prefer_deployed_tasks("auv_control_#{convertion_name}").
                        with_conf('default', convertion_name)
                    convertion_child = composition_m.add convertion_m, as: convertion_name
                    producer_pairs.each do |p, srv|
                        child_srv = convertion_child.find_data_service(srv.name)
                        p.bound_service.connect_to child_srv
                    end
                    rule.axis.each do |mask, target|
                        if !(new_axis & mask).empty?
                            new_axis |= target
                        end
                    end

                    return Producer.new(convertion_srv.name, rule.target_domain,
                                        new_axis, convertion_child.find_data_service(convertion_srv.name),
                                        convertion_name)
                end
            end
        end
    end
end

