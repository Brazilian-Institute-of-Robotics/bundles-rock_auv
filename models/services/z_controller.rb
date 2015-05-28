require 'rock_auv/models/services/controller'

module RockAUV
    module Services
        ZController = Controller.for { WorldPos(:z) }
    end
end
