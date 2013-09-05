require 'socket'
require 'io/wait'
require 'comm_codes'

class RobotCommError < RuntimeError
end

class RobotComm
    class KilledWhileWaitingException < RuntimeError
    end

    CONSOLE_PORT = 50000

    attr_writer :controller

    def initialize( id, host )
        @host = host
        @id = id
        @queued_msgs = []
        @console_addr = [ @host, RobotComm::CONSOLE_PORT ]
    end

    def open
        @sock = UDPSocket.new
        @sock.bind( '0.0.0.0', RobotComm::CONSOLE_PORT + @id )
        @sock_out = @sock
    end

    def send_to_console( data )
        @sock_out.send( data, 0, @console_addr[0], @console_addr[1] )
    end

    def check_msgs( wait_for=nil )
        # make sure we the socket has been opened
        raise RobotCommError, "need to open robot (#{@id}) comm" if !@sock

        # handle any queued messages
        if ( !wait_for && !@queued_msgs.empty? )
            @queued_msgs.each { |msg| self.handle_msg( msg ) }
            @queued_msgs = []
        end

        #puts "checking msgs; @sock.ready? = #{@sock.ready?}"

        # keep going while there's messages waiting
        while @controller.running and (wait_for or @sock.ready?)

            # read and handle a message
            msg, sender = @sock.recvfrom( 65536 )
            msg = Marshal.load( msg )

            if ( msg[0] == wait_for )
                return msg
            elsif ( wait_for && (msg[0] != CommCodes::KILL) )
                @queued_msgs << msg
            else
                handle_msg( msg )
            end
        end
    end

    def wait_for_msg( wait_for )
        msg = nil
        while !msg
            msg = check_msgs( wait_for )
            if !@controller.running
                raise RobotComm::KilledWhileWaitingException
            end
        end
        msg
    end

    def handle_msg( msg )
        if ( @@handlers.keys().include? msg[0] )
            send( @@handlers[ msg[0] ],  msg )
        else
            puts "Error: unregistered message number: #{msg[0]}"
        end
    end

    def send_alive_confirmation( pos, color,
                                 max_vel, max_angular_vel, radius )
        s = Marshal.dump( [CommCodes::ALIVE, @id,
                           pos.location.x, pos.location.y, pos.location.z,
                           pos.heading, color, max_vel, max_angular_vel,
                           radius ] )
        send_to_console( s )
    end

    def send_position_update( pos )
        s = Marshal.dump( [CommCodes::POSITION, @id,
                           pos.location.x, pos.location.y, pos.location.z,
                           pos.heading ] )
        send_to_console( s )
    end

    def position
        s = Marshal.dump( [CommCodes::REQUEST_POSITION, @id] )
        send_to_console( s )
        msg = wait_for_msg( CommCodes::POSITION )
        ( type, x, y, z, t ) = msg
        RobotPosition.new( Vector.new( x, y, z ), t )
    end

    def send_death_msg
        s = Marshal.dump( [CommCodes::ROBOT_DYING, @id] )
        send_to_console( s )
    end

    def start_robot( msg )
        @controller.paused = false
    end

    def kill( msg )
        puts "handling kill msg"
        send_death_msg()
        puts "sent death msg; closing socket"
        @sock.close()
        puts "setting controller.running to false"
        @controller.running = false
        puts "set controller.running to false"
    end

    def switch_paused( msg )
        @controller.paused = !@controller.paused
    end

    def get_obs
        s = Marshal.dump( [CommCodes::GET_OBSTACLES, @id] )
        send_to_console( s )
        msg = wait_for_msg( CommCodes::OBS_READINGS )

        obstacles = []
        i = 1
        while ( i < msg.length )
            obstacles << Vector.new( msg[i], msg[i+1], 0 )
            i += 2
        end

        obstacles
    end

    def sim_move( movement )
        s = Marshal.dump( [CommCodes::MOVE, @id,
                           movement.x, movement.y] )
        send_to_console( s )
    end

    @@handlers = { CommCodes::START => :start_robot,
                   CommCodes::KILL =>  :kill,
                   CommCodes::PAUSE => :switch_paused }
end
