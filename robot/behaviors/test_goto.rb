require 'geom_utils'
require 'robot/behaviors/avoid_obs'
require 'robot/behaviors/behavior'
require 'robot/behaviors/get_obs'
require 'robot/behaviors/get_position'
require 'robot/behaviors/global_to_egocentric'
require 'robot/behaviors/literal'
require 'robot/behaviors/move_robot'
require 'robot/behaviors/move_to'
require 'robot/behaviors/sum_vectors'
require 'robot/behaviors/wander'

Vector = GeomUtils::Vector

module Behaviors

class TestGoto < Behavior
    def initialize( name=nil )
        super( name )

        @move_robot = MoveRobot.new(
            nil,
            SumVectors.new(
                nil,
                [ MoveTo.new( nil,
                              GlobalToEgocentric.new( nil,
                                                      GetPosition.new,
                                                      Literal.new( nil, Vector.new( 49, 49 ) ) ) ),
                  AvoidObs.new( nil,
                                GetObs.new,
                                Literal.new( nil, 1.5 ),
                                Literal.new( nil, 5 ) ),
                  Wander.new( nil, Literal.new( nil, 10 ) ) ],
                [ Literal.new( nil, 1 ), Literal.new( nil, 1 ), Literal.new( nil, 0.3 ) ] ),
            Literal.new( nil, 1 ),
            Literal.new( nil, 1 ) )
    end

    def connect_inputs
    end

    def compute_output
        @move_robot.output
    end
end # of TestGoto
end # of Behaviors
