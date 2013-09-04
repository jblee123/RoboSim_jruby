require 'robot/behaviors/behavior'

require 'pp'
module Behaviors

class MoveRobotError < RuntimeError
end

class MoveRobot < Behavior
    def initialize( name=nil, movement=nil, base_speed=nil, max_speed=nil )
        super( name )
        @movement = movement
        @base_speed = base_speed
        @max_speed = max_speed
    end

    def compute_output
        raise MoveRobotError, 'no robot interface' if !robot_interface
        raise MoveRobotError, 'movement input not set' if !@movement

        vec = @movement.output * @base_speed.output
        if ( vec.length > @max_speed.output )
            vec = vec.get_unit * @max_speed.output
        end

        robot_interface.move( vec )
    end
end # of MoveRobot
end # of Behaviors
