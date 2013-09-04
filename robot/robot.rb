require 'robot_position'
require 'robot/controller'
require 'robot/robot'
require 'robot/robot_comm'
require 'robot/robot_interfaces/sim_robot_interface'

class Robot

    attr_reader :behaviors, :communicator, :interface

    @@robot_instance = nil

    def Robot.robot_instance
        @@robot_instance
    end

    def initialize( id,
                    host='localhost',
                    type='simulation',
                    x_pos=1,
                    y_pos=1,
                    theta=0,
                    color='blue',
                    max_vel=-1,
                    max_angular_vel=-1,
                    radius=0.5 )

        @@robot_instance = self

        @cycle_num = 0
        @behaviors = {}

        @id = id
        @host = host
        @color = color
        @max_vel = max_vel
        @max_angular_vel = max_angular_vel
        @radius = radius

        # set up the robot type
        if ( type == 'simulation' )
            @interface = SimRobotInterface.new
        else
            print "Error: robot type '%s' not currently supported" % type
            exit( -1 )
        end

        pos = RobotPosition.new( GeomUtils::Vector.new( x_pos, y_pos ), theta )

        # init communication back to the console
        @communicator = RobotComm.new( id, host )
        @communicator.open
        @communicator.send_alive_confirmation( pos, color, max_vel, max_angular_vel, radius )

        @controller = Controller.new

        # link the controller and communicator to each other
        @controller.communicator = @communicator
        @communicator.controller = @controller

        @interface.communicator = @communicator
        @interface.position = pos
    end

    def get_cycle
        @cycle_num
    end

    def increment_cycle
        @cycle_num += 1
    end

    def add_behavior( behavior )
        @controller.add_behavior( behavior )
    end

    def run
        @controller.run
    end

end # of Robot