require 'geom_utils'
require 'socket'
require 'io/wait'
require 'comm_codes'
require 'robot_position'

require 'pp'
require 'jruby/profiler'

Vector = GeomUtils::Vector

class ConsoleCommError < RuntimeError
end

class ConsoleComm
    CONSOLE_PORT = 50000

    attr_reader :sock

    def initialize( app_instance=nil )
        @app_instance = app_instance
        @sock = nil

        @addresses = {}
    end

    def open
        @sock = UDPSocket.new
        @sock.bind( '0.0.0.0', ConsoleComm::CONSOLE_PORT )
        @sock_out = @sock
    end

    def send_to_robot( data, id )
        addr = @addresses[ id ]
        @sock_out.send( data, 0, addr[0], addr[1] )
    end

    def send_to_all_robots( data, p = false )
        @addresses.keys.each { |id|
            send_to_robot( data, id ) }
    end

    def check_for_msgs
        # make sure we the socket has been opened
        raise ConsoleCommError, 'need to open console comm' if !@sock

        # keep going while there's messages waiting
        while @sock.ready?
            # read and handle a message
            msg, sender = @sock.recvfrom( 65536 )
            msg = Marshal.load( msg )
            if ( msg[0] == CommCodes::ALIVE )
                register_new_robot( msg, sender )
            else
                handle_msg( msg )
            end
        end

        # tell the console to check for messages again later
        @app_instance.schedule_msg_check if @app_instance
    end

    def register_new_robot( msg, address )
        ( type, id, x, y, z, t, color, max_vel, max_angular_vel, radius ) = msg

        pos = RobotPosition.new( Vector.new( x, y, z ), t )

        # see if we've already registered this ID
        if ( @addresses.keys().include? id )
            puts "Error: ID #{id} is being re-used"
            sys.exit( -1 )
        end

        # register the ID
        @addresses[ id ] = [ address[3], address[1] ]
        @app_instance.simulator.register_robot(
            id, pos, color, max_vel, max_angular_vel, radius )
    end

    def handle_msg( msg )
        if ( @@handlers.keys().include? msg[0] )
            send( @@handlers[ msg[0] ], msg )
        else
            puts "Error: unregistered message number: #{msg[0]}"
        end
    end

    def update_robot_pos( msg )
        ( type, id, x, y, z, t ) = msg
        pos = RobotPosition.new( Vector.new( x, y, z ), t )
        @app_instance.simulator.update_robot_pos( id, pos )
    end

    def get_robot_pos( msg )
        ( type, id ) = msg
        pos = @app_instance.simulator.get_robot_pos( id )
        if pos
            s = Marshal.dump( [CommCodes::POSITION, pos.location.x,
                               pos.location.y, pos.location.z, pos.heading] )
            send_to_robot( s, id )
        end
    end

    def send_start_msg( id )
        s = Marshal.dump( [CommCodes::START] )
        send_to_robot( s, id )
    end

    def send_killall
        s = Marshal.dump( [CommCodes::KILL] )
        send_to_all_robots( s )
    end

    def send_switch_pause
        s = Marshal.dump( [CommCodes::PAUSE] )
        send_to_all_robots( s )
    end

    def get_obs_readings( msg )
        id = msg[1]
        readings = @app_instance.simulator.get_obs_readings( id )
        data = [ CommCodes::OBS_READINGS, ]
        readings.each do |reading|
            data << reading.x
            data << reading.y
        end
        data = Marshal.dump( data )
        send_to_robot( data, id )
    end

    def robot_dying( msg )
        id = msg[1]
        @addresses.delete( id )
        @app_instance.simulator.robot_dying( id )
    end

    def move_robot( msg )
        ( type, id, x, y ) = msg
        @app_instance.simulator.move_robot( id, x, y )
    end

    def spin_robot( msg )
        ( type, id, theta ) = msg
        @app_instance.simulator.spin_robot( id, theta )
    end

    @@handlers = { CommCodes::POSITION =>         :update_robot_pos,
                   CommCodes::REQUEST_POSITION => :get_robot_pos,
                   CommCodes::GET_OBSTACLES =>    :get_obs_readings,
                   CommCodes::ROBOT_DYING =>      :robot_dying,
                   CommCodes::MOVE =>             :move_robot,
                   CommCodes::SPIN =>             :spin_robot }
end # of ConsoleComm
