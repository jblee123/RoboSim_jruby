require 'robot/behaviors/behavior'

module Behaviors

class LiteralError < RuntimeError
end

class Literal < Behavior
    def initialize( name=nil, val=nil )
        super( name )
        @output = val if val != nil
    end

    def compute_output
        raise LiteralError, 'output not set' if @output == nil
    end
end # of Literal
end # of Behaviors
