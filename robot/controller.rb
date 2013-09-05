require 'robot/robot_comm'

class Controller

    attr_reader :paused, :running
    attr_writer :communicator, :paused, :running

    def initialize( behaviors_to_run=[] )
        @communicator = nil
        @behaviors_to_run = behaviors_to_run
        @paused = true
        @running = true
    end

    def add_behavior( to_add )
        @behaviors_to_run << to_add
    end

    def robot_instance
        Robot.robot_instance
    end

    def run
        # make sure all the behaviors are connected up
        robot_instance.behaviors.values.each do |behavior|
            behavior.connect_inputs
        end

        while @running
            # check for msgs
            robot_instance.communicator.check_msgs()

            # don't do anything if we're paused
            if ( @paused )
                sleep(0.001)
                next
            end

            if @running
                # run all the top-level behaviors
                begin
                    @behaviors_to_run.each do |behavior|
                        behavior.output
                    end
                    robot_instance.increment_cycle
                rescue RobotComm::KilledWhileWaitingException
                end

                sleep(0.001)
            end
        end
        puts "robot controller.run returning"
    end
end
