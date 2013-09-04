require 'robot/behaviors/behavior'

module Behaviors

class GetObsError < RuntimeError
end

################################################################################
#
# Inputs:
#
################################################################################

class GetObs < Behavior
    def initialize( name=nil )
        super( name )
    end

    def compute_output
        raise GetObsError, 'no robot interface' if !robot_interface

        @output = robot_interface.obs_readings
    end
end # of GetObs
end # of Behaviors
