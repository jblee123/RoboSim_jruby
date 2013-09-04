require 'robot/behaviors/behavior'

module Behaviors

class GetPositionError < RuntimeError
end

class GetPosition < Behavior
    def initialize( name=nil )
        super( name )
    end

    def compute_output
        raise GetPositionError, 'no robot interface' if !robot_interface

        @output = robot_interface.position
    end
end # of GetPosition
end # of Behaviors
