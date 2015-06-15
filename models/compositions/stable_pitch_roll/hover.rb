require 'rock/models/services/position'
require 'rock_auv/models/compositions/stable_pitch_roll/constant_world_pos_xy_control'

module RockAUV
    module Compositions
        module StablePitchRoll
            class Hover < Syskit::Composition
                add Rock::Services::Position, as: 'xy_samples'

                add(ConstantWorldPosXYControl, as: 'xy_control').
                    use('xy_samples' => xy_samples_child)

                event :acquired_initial_position

                attr_reader :initial_position

                def self.instanciate(*args)
                    cmp = super
                    cmp.acquired_initial_position_event.add_causal_link \
                        cmp.xy_control_child.start_event
                    cmp
                end

                script do
                    # First, read the current positio
                    xy_reader = xy_samples_child.position_samples_port.reader
                    poll_until(acquired_initial_position_event) do
                        if @initial_position = xy_reader.read
                            acquired_initial_position_event.emit
                        end
                    end

                    execute do
                        xy_control_child.setpoint =
                            Hash[x: initial_position.position.x, y: initial_position.position.y]
                    end
                end
            end
        end
    end
end
