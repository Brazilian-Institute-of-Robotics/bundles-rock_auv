using_task_library 'auv_control'
require 'rock_auv/models/compositions/control/rule'
require 'rock_auv/models/services/controller'
require 'rock/models/compositions/constant_generator'

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
                Axis = Services::Control::Axis

                RULES = [
                    Rule.new("pos_world2aligned", [:world,:pos], [:aligned,:pos], Hash[Axis.new(:x,:y) => Axis.new(:x,:y)], AuvControl::WorldToAligned),
                    Rule.new("vel_world2aligned", [:world,:vel], [:aligned,:vel], Hash[Axis.new(:x,:y) => Axis.new(:x,:y)], AuvControl::WorldToAligned),
                    Rule.new("aligned_pos2vel", [:aligned,:pos], [:aligned,:vel], Hash[], AuvControl::PIDController),
                    Rule.new("aligned_vel2effort", [:aligned,:vel], [:aligned,:effort], Hash[], AuvControl::PIDController),
                    Rule.new("effort_aligned2body", [:aligned,:effort], [:body,:effort], Hash[Axis.new(:x,:y,:z) => Axis.new(:x,:y,:z)], AuvControl::AlignedToBody)]

                Producer = Struct.new :name, :domain, :axis, :bound_service do
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
                    result = Cascade.new_submodel

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
                            debug do
                                debug "applying #{resolved_producers.size} producers"
                                resolved_producers.each do |p|
                                    debug "  #{p}"
                                end
                                break
                            end
                            new_axis, new_producer = self.class.apply_rule(result, rule, resolved_producers)
                            producers_by_domains[rule.target_domain] ||= Array.new
                            producers_by_domains[rule.target_domain] << Producer.new(rule.name, rule.target_domain, new_axis, new_producer)
                        end
                    end
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
                # @param [Model<Component>] producer the producer component
                # @return [Array<Producer>]
                def self.producer_elements(name, producer)
                    srv = producer.find_data_service_from_type(Services::Controller)
                    if !srv
                        raise ArgumentError, "#{producer} does not provide #{Services::Controller}"
                    end
                    # We want the actual service, not the service-as-Controller
                    srv = srv.as_real_model

                    result = Array.new
                    srv.model.domain.each do |reference, quantity, axis|
                        base_srv = Services::Controller.for(Services::Control::Domain.new(reference, quantity, axis))
                        result << Producer.new(name, [reference,quantity], axis, srv.as(base_srv))
                    end
                    result
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
                            :as => p.name)]
                    end

                    reference, quantity = *rule.target_domain
                    output_srv = Control::OUTPUTS[reference][quantity]
                    convertion_m.provides output_srv, :as => 'cmd',
                        "cmd_out_#{reference}_#{quantity}" => "cmd_out"

                    convertion_child = composition_m.add convertion_m, :as => rule.name
                    producer_pairs.each do |p, srv|
                        child_srv = convertion_child.find_data_service(srv.name)
                        p.srv.connect_to child_srv
                    end
                    rule.axis.each do |mask, target|
                        if new_axis & mask != 0
                            new_axis |= target
                        end
                    end

                    return new_axis, convertion_child.cmd_srv
                end
            end
        end
    end
end

