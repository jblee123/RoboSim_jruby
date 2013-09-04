require 'robot/behaviors/behavior'

module Behaviors

class MoveToError < RuntimeError
end

class MoveTo < Behavior
    def initialize( name=nil, target=nil )
        super( name )
        @target = target
    end

    def compute_output
        raise MoveToError, 'target input not set' if !@target

        @output = @target.output.get_unit
    end
end # of MoveTo
end # of Behaviors
