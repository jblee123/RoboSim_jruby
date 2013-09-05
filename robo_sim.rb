include Java

require 'lib/spoon'
require 'console/environment'
require 'console/simulator'
require 'console/robo_sim_frame'
require 'console/console_comm'

class RoboSim

    attr_reader :simulator, :communicator, :environment, :shutting_down, :shut_down

    def initialize( environment )
        schedule_init environment
    end

    def exit_robo_sim
        #exit
        @shut_down = true
    end

    def initiate_shutdown
        puts "initiating shutdown"
        @shutting_down = true
        @communicator.send_killall()

        t = javax.swing.Timer.new( 5000, nil )
        t.add_action_listener { |e|
            exit_robo_sim
        }
        t.setRepeats( false )
        t.start
    end

    def schedule_init( environment )
        t = javax.swing.Timer.new( 1, nil )
        t.add_action_listener do |e|
            @shutting_down = false
            @shut_down = false

            @environment = environment
            @simulator = Simulator.new( self )

            @console = RoboSimFrame.new( self )

            @communicator = ConsoleComm.new( self )
            @communicator.open
            schedule_msg_check
        end
        t.setRepeats( false )
        t.start
    end

    def schedule_msg_check
        if not @shut_down
            t = javax.swing.Timer.new( 0, nil )
            t.add_action_listener { |e| @communicator.check_for_msgs }
            t.setRepeats( false )
            t.start
        end
    end
end

################################################################################
RUN_ANYWAY = 1
if ( RUN_ANYWAY )
    e = Environment.new( 50, 50 )
#    e.add_obstacle( 'obstacle', Obstacle(  5,  5, 1 ) )
    e.add_obstacle( Obstacle.new( 10, 10, 2 ) )
    e.add_obstacle( Obstacle.new( 15, 15, 3 ) )
    e.add_wall( Wall.new( 15, 35, 25, 35 ) )
    e.add_wall( Wall.new( 25, 35, 35, 25 ) )
    #e.add_wall( Wall.new( 35, 25, 35, 15 ) )
    e.add_item( Item.new( 49, 49,  1, 'red' ) )

#    e.add( 'wall', Wall( 15, 15, 15, 35 ) )
#    e.add( 'wall', Wall( 15, 35, 35, 35 ) )
#    e.add( 'wall', Wall( 35, 35, 35, 15 ) )
#    e.add( 'wall', Wall( 35, 15, 15, 15 ) )


    # e.add_wall( Wall.new( 10, 10, 10, 40 ) )
    # e.add_wall( Wall.new( 10, 40, 40, 40 ) )
    # e.add_wall( Wall.new( 40, 40, 40, 10 ) )
    # e.add_wall( Wall.new( 40, 10, 10, 10 ) )






    app = RoboSim.new( e )

    class_file = "robot/robot_test.class"
    rb_file = "robot/robot_test.rb"
    exec_target = ((File.exist?(class_file) and class_file) or
                   (File.exist?(rb_file) and rb_file))

    #cmd = "jruby robot/robot_test.rb -i 1 -x 1 -y 1 -c blue -v 1 -a 20"
    #Spoon.spawnp( 'jruby', '--profile', exec_target, '-i', '1', '-x', '1', '-y', '1', '-c', 'blue', '-v', '1', '-a', '20' )
    Spoon.spawnp( 'jruby', exec_target, '-i', '1', '-x', '1', '-y', '1', '-c', 'blue', '-v', '1', '-a', '20' )

    while not app.shut_down
        sleep 1
    end

    puts "ending"
end