require 'robot/behaviors/behavior'

module Behaviors

class GlobalToEgocentricError < RuntimeError
end

class GlobalToEgocentric < Behavior
    def initialize( name=nil, robot_pos=nil, global_pos=nil )
        super( name )
        @robot_pos  = robot_pos
        @global_pos = global_pos
    end

    def compute_output
        raise GlobalToEgocentricError, 'robot_pos input not set' if !@robot_pos
        raise GlobalToEgocentricError, 'global_pos input not set' if !@global_pos

        robot_pos = @robot_pos.output
        global_pos = @global_pos.output

        @output = ( global_pos - robot_pos.location ).rotate_z( robot_pos.heading * -1 )
    end
end # of GlobalToEgocentric
end # of Behaviors
