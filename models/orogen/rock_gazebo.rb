require 'rock/models/orogen/rock_gazebo'
require 'rock_auv/models/devices/gazebo/thrusters'

class OroGen::RockGazebo::ThrusterTask
    # Customizes the configuration step.
    #
    # The orocos task is available from orocos_task
    #
    # The call to super here applies the configuration on the orocos task. If
    # you need to override properties, do it afterwards
    #
    # def configure
    #     super
    # end
    
    driver_for RockAUV::Devices::Gazebo::Thrusters, as: 'thrusters'
end


