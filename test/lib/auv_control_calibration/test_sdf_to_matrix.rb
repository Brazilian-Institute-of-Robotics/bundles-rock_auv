require 'rock_auv/auv_control_calibration/sdf_to_matrix'
require 'fakefs/safe'

module RockAUV
    module ControllerCalibration
        describe 'sdf_load_model_from_file' do
            before do
                FakeFS.activate!
            end
            after do
                FakeFS.deactivate!
                FakeFS::FileSystem.clear
            end

            it 'raises ArgumentError if there is no model in the file' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"></sdf>' }
                assert_raises(ArgumentError) { ControllerCalibration.sdf_load_model_from_file('/entry.sdf') }
            end
            it 'raises ArgumentError if there is more than one model in the file' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><model name="m1" /><model name="m2" /></sdf>' }
                assert_raises(ArgumentError) { ControllerCalibration.sdf_load_model_from_file('/entry.sdf') }
            end
            it 'detects an ambiguity if one model is child of a world' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><world><model name="m1" /></world><model name="m2" /></sdf>' }
                assert_raises(ArgumentError) { ControllerCalibration.sdf_load_model_from_file('/entry.sdf') }
            end
            it 'selects the model whose name is given' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><world><model name="m1" /></world><model name="m2" /></sdf>' }
                m = ControllerCalibration.sdf_load_model_from_file('/entry.sdf', model_name: 'm1')
                assert_kind_of SDF::Model, m
                assert_equal "m1", m.name
            end
            it 'raises ArgumentError if the model whose name is given does not exist' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><world><model name="m1" /></world><model name="m2" /></sdf>' }
                assert_raises(ArgumentError) { ControllerCalibration.sdf_load_model_from_file('/entry.sdf', model_name: 'does_not_exist') }
            end
            it 'returns the model if there is exactly one' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><model name="m1" /></sdf>' }
                m = ControllerCalibration.sdf_load_model_from_file('/entry.sdf')
                assert_kind_of SDF::Model, m
                assert_equal "m1", m.name
            end
            it 'returns the model even if it is the child of a world' do
                File.open("/entry.sdf", 'w') { |io| io.write '<sdf version="1.5"><world><model name="m1" /></world></sdf>' }
                m = ControllerCalibration.sdf_load_model_from_file('/entry.sdf')
                assert_kind_of SDF::Model, m
                assert_equal "m1", m.name
            end
        end

        describe "sdf_to_thruster_matrix" do
            it "raises if a thruster does not exist" do
                xml = REXML::Document.new('<sdf><model><plugin name="thrusters"><thruster link_name="does_not_exist" /></plugin><link name="thr"><pose>1 2 10 5 -5 10</pose></link></model></sdf>')
                model = SDF::Root.new(xml.root).each_model.first
                assert_raises(ArgumentError) { ControllerCalibration.sdf_to_thruster_matrix(model) }
            end

            it "extracts the links poses and converts them" do
                xml = REXML::Document.new('<sdf><model><plugin name="thrusters"><thruster link_name="thr" /></plugin><link name="thr"><pose>1 2 10 5 -5 10</pose></link></model></sdf>')
                model = SDF::Root.new(xml.root).each_model.first

                expected_pose = model.each_link.first.pose
                flexmock(ControllerCalibration).should_receive(:sdf_thrusters_to_matrix).
                    with( -> poses { poses.size == 1 && poses[0].approx?(expected_pose) }).
                    and_return(ret = flexmock).
                    once
                assert_equal ret, ControllerCalibration.sdf_to_thruster_matrix(model)
            end
        end

        describe "sdf_thrusters_to_matrix" do
            it "generates linear effort" do
                pose = Eigen::Isometry3.Identity
                matrix = ControllerCalibration.sdf_thrusters_to_matrix([pose])
                solver = matrix.jacobiSvd(Eigen::ComputeThinU | Eigen::ComputeThinV)
                cmd = solver.solve(Eigen::VectorX.from_a([1, 0, 0, 0, 0, 0]))
                assert Eigen::VectorX.from_a([1]).approx?(cmd), "#{cmd.to_a}"
            end
            it "generates pure linear thrust from symmetric thrusters" do
                pose0 = Eigen::Isometry3.Identity
                pose0.translate(Eigen::Vector3.UnitY)
                pose1 = Eigen::Isometry3.Identity
                pose1.translate(-Eigen::Vector3.UnitY)

                matrix = ControllerCalibration.sdf_thrusters_to_matrix([pose0, pose1])
                solver = matrix.jacobiSvd(Eigen::ComputeThinU | Eigen::ComputeThinV)
                cmd = solver.solve(Eigen::VectorX.from_a([1, 0, 0, 0, 0, 0]))
                assert Eigen::VectorX.from_a([0.5, 0.5]).approx?(cmd), "#{cmd.to_a}"
            end
            it "generates pure angular thrust from symmetric thrusters" do
                pose0 = Eigen::Isometry3.Identity
                pose0.translate(Eigen::Vector3.UnitY)
                pose1 = Eigen::Isometry3.Identity
                pose1.translate(-Eigen::Vector3.UnitY)

                matrix = ControllerCalibration.sdf_thrusters_to_matrix([pose0, pose1])
                solver = matrix.jacobiSvd(Eigen::ComputeThinU | Eigen::ComputeThinV)
                cmd = solver.solve(Eigen::VectorX.from_a([0, 0, 0, 0, 0, 1]))
                assert Eigen::VectorX.from_a([-0.5, 0.5]).approx?(cmd), "#{cmd.to_a}"
            end
        end
    end
end

