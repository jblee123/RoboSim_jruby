require 'geom_utils'
require 'robot/behaviors/behavior'

module Behaviors

class SumVectorsError < RuntimeError
end

class SumVectors < Behavior
    def initialize( name=nil, vectors=nil, weights=nil )
        super( name )
        @vectors = vectors
        @weights = weights
    end

    def compute_output
        raise SumVectorsError, 'vectors input not set' if !@vectors
        raise SumVectorsError, 'weights input not set' if !@weights
        raise SumVectorsError, 'vectors.length != weights.length' if @vectors.length != @weights.length

        @output = Vector.new( 0, 0, 0 )

        @vectors.zip( @weights ).each do |v, w|
            @output += v.output * w.output
        end
    end
end # of SumVectors
end # of Behaviors
