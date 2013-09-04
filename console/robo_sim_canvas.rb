include Java

java_import javax.swing.JPanel
java_import java.awt.Color
java_import java.awt.Polygon
java_import java.awt.Rectangle
java_import java.awt.RenderingHints

require 'geom_utils'

class RoboSimCanvasError < RuntimeError
end

class RoboSimCanvas < JPanel

    def initialize( environment=nil, simulator=nil, scale=nil )
        super()
        @environment = environment
        @simulator = simulator
        @scale = scale

        @obs_readings = {}

        simulator.add_state_changed_listener( self )
    end

    def simulation_state_changed( simulator, params=nil )
        if params
            if ( params['type'] == 'obs_readings' )

                bounds = nil
                calc_obs_redraw_bounds = lambda {
                    (@obs_readings[ params['robot_id'] ] or []).each do |reading|
                        x, y = @scale.meters_to_pixels( reading.x, reading.y )
                        if !bounds
                            bounds = Rectangle.new( x - 3, y - 3, 6, 6 )
                        else
                            bounds.add( x - 3, y - 3 )
                            bounds.add( x + 3, y + 3 )
                        end
                    end
                }

                calc_obs_redraw_bounds.call
                @obs_readings[ params['robot_id'] ] = params['readings']
                calc_obs_redraw_bounds.call
                if bounds
                    paintImmediately bounds
                end

                # redraw_obs = lambda {
                #     (@obs_readings[ params['robot_id'] ] or []).each do |reading|
                #         x, y = @scale.meters_to_pixels( reading.x, reading.y )
                #         paintImmediately( Rectangle.new( x - 3, y - 3, 6, 6 ) )
                #     end
                # }

                # redraw_obs.call
                # @obs_readings[ params['robot_id'] ] = params['readings']
                # redraw_obs.call


            elsif ( params['type'] == 'robot_pos' )
                old_pos = params['old_pos']
                new_pos = params['new_pos']
                d = @scale.meter_to_pixel_dist( 1 )
                x, y = @scale.meters_to_pixels( old_pos.location.x, old_pos.location.y )
                bounds = Rectangle.new( x - d, y - d, 2*d, 2*d )
                x, y = @scale.meters_to_pixels( new_pos.location.x, new_pos.location.y )
                bounds.add( Rectangle.new( x - d, y - d, 2*d, 2*d ) )
                paintImmediately bounds
            end
        end
        #repaint
        if !params
            paintImmediately Rectangle.new( getSize )
        end

        # r = @simulator.robots.values.first
        # #puts r
        # if r
        #     x, y = @scale.meters_to_pixels( r.pos.location.x, r.pos.location.y )
        #     d = @scale.meter_to_pixel_dist( 1 )
        #     repaint( x - d, y - d, 2*d, 2*d )
        # end
    end

    def paint( g )
        # call_time = Time.new
        # if ( @last_call_time )
        #     puts "since last call time: #{call_time-@last_call_time}"
        # end
        # @last_call_time = call_time
        #t1 = Time.new
        g.set_rendering_hint( RenderingHints::KEY_ANTIALIASING,
                              RenderingHints::VALUE_ANTIALIAS_ON )
        g.setColor( Color::WHITE )
        g.fillRect( 0, 0, getWidth, getHeight )

        puts "no environment" if !@environment
        puts "no simulator" if !@simulator
        puts "no scale" if !@scale

        return if !@environment
        return if !@simulator
        return if !@scale

        @environment.obstacle_list.each do |item|
            draw_obstacle( g, item )
        end

        @environment.wall_list.each do |item|
            draw_wall( g, item )
        end

        @environment.label_list.each do |item|
            draw_label( g, item )
        end

        @environment.item_list.each do |item|
            draw_item( g, item )
        end

        @simulator.robots.values.each do |item|
            draw_robot( g, item )
        end

        @obs_readings.values.each do |readings|
            draw_readings( g, readings )
        end
        #t2 = Time.new
        #puts "time: #{t2-t1}"
        #puts ""
    end

    def draw_obstacle( g, obs )
        ( x, y ) = @scale.meters_to_pixels( obs.x, obs.y )
        r = @scale.meters_to_pixels( obs.r, 0 )[0]
        g.setColor( Color::BLACK )
        g.fillOval( x-r, y-r, r*2, r*2 )
    end

    def draw_wall( g, wall )
        ( x1, y1 ) = @scale.meters_to_pixels( wall.x1, wall.y1 )
        ( x2, y2 ) = @scale.meters_to_pixels( wall.x2, wall.y2 )
        g.setColor( Color::BLACK )
        g.drawLine( x1, y1, x2, y2 )
    end

    def draw_label( g, label )
        # todo - not yet implemented
    end

    def draw_item( g, obj )
        ( x, y ) = @scale.meters_to_pixels( obj.x, obj.y )
        r = @scale.meters_to_pixels( obj.r, 0 )[0]
        g.setColor( Color.send( obj.color.downcase ) )
        g.fillOval( x-r, y-r, r*2, r*2 )
    end

    def draw_readings( g, readings )
        readings.each do |reading|
            x, y = @scale.meters_to_pixels( reading.x, reading.y )
            g.setColor( Color::RED )
            g.drawOval( x-2, y-2, 2*2, 2*2 )
        end
    end

    def draw_robot( g, robot )
        point1 = Vector.new( -0.5,  0.5 )
        point2 = Vector.new(  0.5,  0.5 )
        point3 = Vector.new(  1.0,  0.0 )
        point4 = Vector.new(  0.5, -0.5 )
        point5 = Vector.new( -0.5, -0.5 )

        p = robot.pos.location
        point1 = point1.rotate_z( robot.pos.heading ) + p
        point2 = point2.rotate_z( robot.pos.heading ) + p
        point3 = point3.rotate_z( robot.pos.heading ) + p
        point4 = point4.rotate_z( robot.pos.heading ) + p
        point5 = point5.rotate_z( robot.pos.heading ) + p
        x1, y1 = @scale.meters_to_pixels( point1.x, point1.y )
        x2, y2 = @scale.meters_to_pixels( point2.x, point2.y )
        x3, y3 = @scale.meters_to_pixels( point3.x, point3.y )
        x4, y4 = @scale.meters_to_pixels( point4.x, point4.y )
        x5, y5 = @scale.meters_to_pixels( point5.x, point5.y )

        robot_poly = java.awt.Polygon.new
        robot_poly.addPoint( x1, y1 )
        robot_poly.addPoint( x2, y2 )
        robot_poly.addPoint( x3, y3 )
        robot_poly.addPoint( x4, y4 )
        robot_poly.addPoint( x5, y5 )

        g.setColor( Color.send( robot.color.downcase ) )
        g.fillPolygon( robot_poly )
    end
end
