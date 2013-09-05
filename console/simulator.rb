require 'set'
require 'geom_utils'
require 'pp'

class RobotInfo

    attr_reader :pos, :color, :max_vel, :max_angular_vel, :radius
    attr_writer :pos, :color, :max_vel, :max_angular_vel, :radius

    def initialize( pos=RobotPosition.new( Vector.new( 0, 0, 0 ), 0 ),
                    color='blue', max_vel=-1, max_angular_vel=-1, radius=0.5 )
        @pos = pos
        @color = color
        @max_vel = max_vel
        @max_angular_vel = max_angular_vel
        @radius = radius
    end
end

class Simulator
    NUM_OF_SIM_RAYS = 16

    def initialize( app_instance=nil, time_step=0.2 )
        @app_instance = app_instance
        @time_step = time_step
        @robots = {}
        @state_changed_listeners = Set.new
    end

    def robots
        @robots.dup
    end

    def add_state_changed_listener( l )
        @state_changed_listeners << l
    end

    def remove_state_changed_listener( l )
        @state_changed_listeners.delete( l )
    end

    def fire_state_changed( params=nil )
        @state_changed_listeners.each do |l|
            l.simulation_state_changed( self, params )
        end
    end

    def register_robot( id, pos, color,
                        max_vel, max_angular_vel, radius )
        @robots[ id ] = RobotInfo.new( pos, color,
                                       max_vel, max_angular_vel, radius )
        @app_instance.communicator.send_start_msg( id )
    end

    def update_robot_pos( id, pos )
        if ( @robots.keys.include? id )
            robot = @robots[ id ]
            old_pos = robot.pos
            robot.pos = pos
            fire_state_changed( { 'type' => 'robot_pos', 'old_pos' => old_pos, 'new_pos' => pos } )
        else
            puts 'Error: tried to update an unregistered robot: ' + id.to_s
        end
    end

    def get_robot_pos( id )
        pos = nil
        if ( @robots.keys.include? id )
            pos = @robots[ id ].pos
        else
            puts 'Error: tried to get the position of an unregistered robot: ' + id.to_s
        end
        pos
    end

    def Simulator.global_to_egocentric( robot_pos, to_convert )
        ( to_convert - robot_pos.location ).rotate_z( robot_pos.heading * -1 )
    end

    def Simulator.egocentric_to_global( robot_pos, to_convert )
        to_convert.rotate_z( robot_pos.heading ) + robot_pos.location
    end

    def get_closest_reading( robot, ray_num )
        # create the ray_num'th ray
        ray_angle = ray_num * 360 / Simulator::NUM_OF_SIM_RAYS
        v = Vector.new( 1, 0, 0 ).rotate_z( robot.pos.heading + ray_angle ) + robot.pos.location
        ray = GeomUtils::Ray.new( robot.pos.location, v )

        # get the closest intersection
        closest_dist = 1000000
        closest_reading = nil

        env = @app_instance.environment
        ( env.obstacle_list + env.wall_list ).each do |obs|
            # get the reading depending on the obstacle type
            reading = obs.intersect_with_ray( ray )

            # see if the current obstacle produces the closest reading so far
            if ( reading )
                reading = Simulator.global_to_egocentric( robot.pos, reading )
                dist = reading.length
                if ( dist < closest_dist )
                    closest_dist = dist
                    closest_reading = reading
                end
            end
        end

        closest_reading
    end

    def get_obs_readings( id )
        readings = []
        if ( @robots.keys.include? id )
            robot = @robots[ id ]
            readings = (1..Simulator::NUM_OF_SIM_RAYS).
                map { |i| get_closest_reading( robot, i ) }.
                select { |reading| reading }

            drawable_readings = readings.map { |r| Simulator.egocentric_to_global( robot.pos, r ) }
            fire_state_changed( { 'type' => 'obs_readings', 'robot_id' => id, 'readings' => drawable_readings } )
        end
        readings
    end

#    def get_obs_readings2( id )
#        readings = []
#        if ( id in self.robots.keys() )
#            robot = self.robots[ id ]
#            for obs in self.app_instance.environment.obstacles
#                reading = Vector( obs.x, obs.y, 0 )
#                neg = ( reading * -1 ).get_unit() * obs.r
#                reading = reading - neg
#                reading = reading - robot.pos.location
#                reading.rotate_z( robot.pos.heading * -1 )
#                readings << reading
#        else
#            print 'Error: tried to get obs readings for an unregistered robot:', id
#
#        return readings

    def robot_dying( id )
        @robots.delete( id )
        if ( @app_instance.shutting_down && @robots.keys().empty? )
            @app_instance.exit_robo_sim()
        end
        fire_state_changed
    end

    def constrain_by_robot( requested, robot )
        max_turn = robot.max_angular_vel * @time_step
        angle = requested.angle
        angle = ( angle < 180 ) ?
            [ angle * @time_step, max_turn ].min :
            [ ( angle - 360 ) * @time_step, -max_turn ].max
        dist = [ robot.max_vel * @time_step,
                 requested.length * @time_step ].max
        Vector.new( dist, 0, 0 ).rotate_z( angle )
    end

    def constrain_by_environment( from_vec, to_vec, robot_radius )
        ray = GeomUtils::Ray.new( from_vec, to_vec )
        delta = to_vec - from_vec
        ray_len = delta.length
        max_collision_dist = ray_len + robot_radius

        closest_dist = 1000000
        closest_intersection = nil

        # look in the obstacles for the closest reading
        env = @app_instance.environment
        ( env.obstacle_list + env.wall_list ).each do |obs|
            # get the intersection depending on the obstacle type
            intersection = obs.intersect_with_ray( ray )

            # see if the current obstacle produces the closest
            #  intersection so far
            if ( intersection )
                intersection_dist = ( intersection - from_vec ).length
                if ( ( intersection_dist < max_collision_dist ) &&
                     ( intersection_dist < closest_dist ) )
                    closest_dist = intersection_dist
                    closest_intersection = intersection
                end
            end
        end

        # if the robot's movement intersects an obstacle, produce a
        #  movement vector that stops short of that obstacle
        closest_intersection ? delta.get_unit() * ( closest_dist - robot_radius ) : delta
    end

    def move_robot( id, x, y )
        if ( @robots.keys.include? id )
            robot = self.robots[ id ]
            requested = Vector.new( x, y, 0 )
            old_pos = robot.pos

            # make sure the robot doesn't violate max velocity and
            # angular velocity constraints
            v = constrain_by_robot( requested, robot )

            v = v.rotate_z( robot.pos.heading ) # switch to real-world direction
            robot.pos.heading = v.angle   # we've already got the new heading

            # make sure the robot doesn't violate any environmental constraints
            v = constrain_by_environment(
                robot.pos.location, robot.pos.location + v, robot.radius )

            # update the robot's position and re-draw it
            robot.pos.location = robot.pos.location + v
            fire_state_changed( { 'type' => 'robot_pos', 'old_pos' => old_pos, 'new_pos' => robot.pos } )
        else
            puts 'Error: tried to move an unregistered robot: ' + id.to_s
        end
    end

    # todo -- this doesn't seem to actually be implemented... :(
    def spin_robot( id, theta )
        if ( @robots.keys.include? id )
            pos = @robots[ id ]
        else
            puts 'Error: tried to spin an unregistered robot: ' + id.to_s
        end
    end
end # of Simulator
