require 'sdf'

module RockAUV
    module AUVControlCalibration
        def self.sdf_load_model_from_file(path, model_name: nil)
            sdf = SDF::Root.load(path.to_str)
            models = sdf.each_model(recursive: true).to_a
            if !model_name
                if models.empty?
                    raise ArgumentError, "SDF file #{sdf} does not contain any models"
                elsif models.size > 1
                    raise ArgumentError, "SDF file #{sdf} has more than one model, select one explicitely by appending ? and the model name to it (e.g. file.sdf?flat_fish)"
                end
                sdf_model = models.first
            elsif !(sdf_model = models.find { |m| m.name == model_name })
                raise ArgumentError, "SDF file #{sdf} does not contain any model called #{model_name}, known models are #{models.map(&:name).sort.join(", ")}"
            end
            sdf_model
        end

        def self.sdf_thrusters_to_matrix(thrusters)
            # Definition of how to compute torque
            torque_desc = [
                [1, 2], # Roll(X) torque  is dY * vZ
                [2, 0], # Pitch(Y) torque is dZ * vX
                [0, 1], # Yaw(Z) torque   is d(X,Y) * v(X,Y)
            ]

            matrix = Eigen::MatrixX.new(6, thrusters.size)
            rpy_axis = [Eigen::Vector3.UnitX, Eigen::Vector3.UnitY, Eigen::Vector3.UnitZ]
            thrusters.each_with_index do |pose, i|
                force = pose.rotation * Eigen::Vector3.UnitX
                3.times do |force_i|
                    matrix[force_i, i] = force[force_i]
                end

                position = pose.translation
                if !Eigen::Vector3.Zero.approx?(position)
                    position = position.normalize
                end
                rpy_axis.each_with_index do |v, torque_i|
                    matrix[3 + torque_i, i] = v.cross(position).dot(force)
                end
            end
            matrix
        end

        def self.sdf_load_thrusters_poses(sdf_model, options = Hash.new)
            options = validate_options options,
                model_name: nil,
                plugin_name: 'thrusters',
                implicit_naming: true

            if sdf_model.respond_to?(:to_str)
                sdf_model = sdf_load_model_from_file(sdf_model, model_name: options[:model_name])
            end

            # Look for the thruster plugin and extract the thruster info
            thruster_plugin = sdf_model.xml.elements["plugin[@name=\"#{options[:plugin_name]}\"]"]
            if !thruster_plugin
                raise ArgumentError, "no thruster plugin in #{sdf_model.full_name}"
            end

            links_by_name = sdf_model.each_link.inject(Hash.new) do |h, l|
                h.merge!(l.name => l)
            end

            result = Hash.new
            if options[:implicit_naming]
                links_by_name.each do |link_name, link|
                    if link_name =~ /^thruster::/
                        result[link_name] = link.pose
                    end
                end
            else
                thruster_plugin.elements.to_a('thruster').map do |thruster_xml|
                    link_name = thruster_xml.attributes['link_name']
                    if !(link = links_by_name[link_name])
                        raise ArgumentError, "thruster refers to link #{link_name} which does not exist"
                    end
                    result[link_name] = link.pose
                end
            end
            result
        end

        # Computes the thruster matrix based on information contained in a SDF
        # file
        #
        # @return [Eigen::MatrixX]
        def self.sdf_to_thruster_matrix(sdf_model, options = Hash.new)
            thrusters = sdf_load_thrusters_poses(sdf_model, options)
            sdf_thrusters_to_matrix(thrusters.values)
        end
    end
end

