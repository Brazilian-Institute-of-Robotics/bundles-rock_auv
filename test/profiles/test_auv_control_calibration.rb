require 'models/profiles/auv_control_calibration'

module RockAUV
    module Profiles
        describe AUVControlCalibration do
            # Verifies that the only variation points in the profile are
            # profile tags. If you want to limit the test to certain definitions,
            # give them as argument
            #
            # You usually want this
            it_should_be_self_contained
        
            # Test if all definitions can be instanciated, i.e. are
            # well-formed networks with no data services
            #it_can_instanciate_all

            # Test if specific definitions can be deployed, i.e. are ready to be
            # started. You want this on the "final" profiles (i.e. the definitions
            # you will run on the robot)
            #it_can_deploy_all

            # If not all definitions can be deployed and/or instanciated, you can
            # use the forms below, which take a list of definitions to test on
            #it_can_deploy a_def
            #it_can_instanciate a_def

            # See the documentation of Syskit::Test::ProfileAssertions and
            # Syskit::Test::ProfileModelAssertions for the assertions on resp.
            # the spec object (to be used in it ... do end blocks) and the spec class
        end
    end
end
