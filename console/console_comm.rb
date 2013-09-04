require 'geom_utils'
require 'socket'
require 'io/wait'
require 'comm_codes'
require 'robot_position'

require 'pp'

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

        @val = 1
    end

    def open
        #puts "creating a new UDP socket and binding to port #{ConsoleComm::CONSOLE_PORT}"
        @sock = UDPSocket.new
        @sock.bind( '0.0.0.0', ConsoleComm::CONSOLE_PORT )
        @sock_out = @sock#UDPSocket.new
        #puts "new @sock.ready?: #{@sock.ready?}"
    end

    def send_to_robot( data, id )
        #puts "id: #{id}, addresses: #{@addresses}"
        #pp @addresses
        addr = @addresses[ id ]
        #puts "addr: #{addr}"
        #pp addr
        #puts "sending to #{addr[0]}:#{addr[1]} data: #{data}"
        #puts "   c send at #{Time.new.to_f}"
        #puts "c send: #{data.length()}"
        @sock_out.send( data, 0, addr[0], addr[1] )
    end

    def send_to_all_robots( data, p = false )
        #puts "sending something to all robots" if p
        @addresses.keys.each { |id|
            #puts "  sending something to a robot" if p
            send_to_robot( data, id ) }
    end

    def check_for_msgs
        # make sure we the socket has been opened
        raise ConsoleCommError, 'need to open console comm' if !@sock

        # if ( true || @sock.ready? || (@val == 1) || ( @val % 1000 ) == 0 )
        #     puts "check_for_msgs: #{@val}, ready: #{@sock.ready?}"# if ( @sock.ready? || (@val == 1) || ( @val % 1000 ) == 0 )
        #     puts "@sock.ready? == nil: #{@sock.ready? == nil}"
        #     puts "@sock.ready? == false: #{@sock.ready? == false}"
        #     puts "@sock.closed?: #{@sock.closed?}"
        #     puts ""
        # end
        # @val += 1

        # keep going while there's messages waiting
        #puts "checking for msgs"
        #went_into_while = false
        while @sock.ready?
            #went_into_while = true
            #puts "  sock should be ready, so reading"
            # see if there's any messages waiting
            #( i, o, e ) = select( [@sock], [], [], 0 )
            #break if !i

            # read and handle a message
            msg, sender = @sock.recvfrom( 65536 )
            #puts "   c recv at #{Time.new.to_f}"
            msg = Marshal.load( msg )
            if ( msg[0] == CommCodes::ALIVE )
                #puts "it was an 'alive' msg"
                register_new_robot( msg, sender )
                #puts "robot is registered"
            else
                handle_msg( msg )
            end
        end
        #puts "done checking" if went_into_while

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
        #puts "registered address for ID #{id}"
    end

    def handle_msg( msg )
        if ( @@handlers.keys().include? msg[0] )
            #puts "handling msg #{msg[0]} with handler #{@@handlers[ msg[0] ]}"
            send( @@handlers[ msg[0] ], msg )
            #puts "msg is handled"
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
        #puts "  getting position at       #{Time.new.to_f}"
        pos = @app_instance.simulator.get_robot_pos( id )
        #puts "  position calculated at    #{Time.new.to_f}"
        if pos
            s = Marshal.dump( [CommCodes::POSITION, pos.location.x,
                               pos.location.y, pos.location.z, pos.heading] )
            #puts "  sending position at       #{Time.new.to_f}"
            send_to_robot( s, id )
            #puts "  position has been sent at #{Time.new.to_f}"
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

    @@handlers = { CommCodes::POSITION,         :update_robot_pos,
                   CommCodes::REQUEST_POSITION, :get_robot_pos,
                   CommCodes::GET_OBSTACLES,    :get_obs_readings,
                   CommCodes::ROBOT_DYING,      :robot_dying,
                   CommCodes::MOVE,             :move_robot,
                   CommCodes::SPIN,             :spin_robot }
end # of ConsoleComm
