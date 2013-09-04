require 'robot/robot_interfaces/robot_interface'

class SimRobotInterface < RobotInterface

    attr_writer :communicator

    def initialize
        super
        @position = RobotPosition.new
        @communicator = nil
    end

    def position
        @communicator.position
    end

    def position=( new_pos )
        @communicator.send_position_update( new_pos )
    end

    def move( movement )
        @communicator.sim_move( movement )
    end

    def obs_readings
        @communicator.get_obs
    end
end
