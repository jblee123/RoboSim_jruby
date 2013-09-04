require 'geom_utils'
require 'robot/behaviors/behavior'

module Behaviors

class AvoidObsError < RuntimeError
end

################################################################################
#
# Inputs: tuple of Vectors obs_list
#         literal scalar safety_margin
#
################################################################################

class AvoidObs < Behavior
    def initialize( name=nil, obs_list=nil,
                    safety_margin=nil, sphere_of_influence=nil )
        super( name )
        @obs_list = obs_list
        @safety_margin = safety_margin
        @sphere_of_influence = sphere_of_influence
    end

    def compute_output
        raise AvoidObsError.new, 'obs_list input not set' if !@obs_list
        raise AvoidObsError.new, 'safety_margin input not set' if !@safety_margin
        raise AvoidObsError.new, 'sphere_of_influence input not set' if !@sphere_of_influence

        obstacles = @obs_list.output
        @output = Vector.new( 0, 0, 0 )
        obstacles.each do |obs|
            length = obs.length
            if ( length < @sphere_of_influence.output )
                if ( length < @safety_margin.output )
                    obs *= 100000
                end
                @output += ( obs * -1 )
            end
        end
    end
end # of AvoidObs
end # of Behaviors
