using_task_library 'rock_gazebo'

module OroGen
    module RockGazebo
        describe ThrusterTask do
            # Gazebo tasks need gazebo to be accessed ... which means
            # interactive. Run these tests only in non-live mode
            run_simulated

            it { is_configurable }
        end
    end
end
