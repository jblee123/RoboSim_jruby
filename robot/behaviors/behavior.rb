require 'robot/robot'

module Behaviors

class Behavior

    @@next_id = 1

    def initialize( name=nil )
        @name = name
        if !name
            @name = 'AN_' + @@next_id.to_s
            @@next_id += 1
        end

        robot.behaviors[ @name ] = self

        @output = nil
        @last_cycle = -2
    end

    def robot
        Robot.robot_instance
    end

    def robot_interface
        robot && robot.interface
    end

    def connect_inputs
    end

    def activate
    end

    def compute_output
        @output = 0
    end

    def output
        cycle_num = robot.get_cycle

        activate if ( ( cycle_num - @last_cycle ) > 2 )

        if ( @last_cycle < cycle_num )
            compute_output
            @last_cycle = cycle_num
        end

        @output
    end
end # of Behavior
end # of Behaviors
