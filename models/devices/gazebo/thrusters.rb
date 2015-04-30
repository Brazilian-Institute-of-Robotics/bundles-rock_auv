require 'rock/models/services/joints_control_loop'

module RockAUV
    module Devices
        module Gazebo
            device_type 'Thrusters' do
                provides Rock::Services::JointsOpenLoopControlledSystem
            end
        end
    end
end
