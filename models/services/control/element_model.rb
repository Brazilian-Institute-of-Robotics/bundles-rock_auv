module RockAUV
    module Services
        module Control
            # Representation as a data service of a single-axis control domain
            class ElementModel < Syskit::Models::DataServiceModel
                # The control domain components providing this are acting on
                #
                # @return [Domain]
                attr_accessor :domain

                def initialize
                    @domain = Domain.new
                    super
                    self.root = true
                    self.supermodel = nil
                    provides Syskit::DataService
                end

                def to_s
                    "RockAUV::Services::Control::Element(#{domain})"
                end
            end
        end
    end
end
