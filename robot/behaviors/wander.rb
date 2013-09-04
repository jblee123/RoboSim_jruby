require 'geom_utils'
require 'robot/behaviors/behavior'

module Behaviors

class WanderError < RuntimeError
end

class Wander < Behavior
    def initialize( name=nil, persistence=nil )
        super( name )
        @persistence = persistence
        @same_direction_count = 0
    end

    def compute_output
        raise WanderError, 'persistence input not set' if !@persistence

        @same_direction_count = 0 if ( @same_direction_count >= @persistence.output )

        if ( @same_direction_count == 0 )
            @output = Vector.new( 1, 0, 0 ).rotate_z( rand * 360 )
        end

        @same_direction_count += 1
    end
end # of Wander
end # of Behaviors
