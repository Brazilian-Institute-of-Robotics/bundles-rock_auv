require 'rock_auv/models/services/controller'

module RockAUV
    module Services
        DepthController = Controller.for { WorldPos(:z) }
    end
end
