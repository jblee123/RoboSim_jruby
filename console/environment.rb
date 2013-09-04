require 'geom_utils'

class Obstacle

    attr_reader :x, :y, :r

    def initialize( x, y, r )
        @x = x
        @y = y
        @r = r
    end

    def intersect_with_ray( ray )
        intersection = nil
        x0, y0 = ray.from_vec.x, ray.from_vec.y
        dx, dy = ray.to_vec.x - x0, ray.to_vec.y - y0
        a = dx**2 + dy**2
        b = 2 * ( x0 * dx - @x * dx + y0 * dy - @y * dy )
        c = x0**2 + @x**2 - 2 * x0 * @x + y0**2 + @y**2 - 2 * y0 * @y - @r**2
        quot = b**2 - 4 * a * c
        if ( quot >= 0 )
            t1 = ( -b + Math.sqrt( quot ) ) / ( 2 * a )
            t2 = ( -b - Math.sqrt( quot ) ) / ( 2 * a )
            v1 = ( t1 >= 0 ) ? Vector.new( x0 + t1 * dx, y0 + t1 * dy, 0 ) : nil
            v2 = ( t2 >= 0 ) ? Vector.new( x0 + t2 * dx, y0 + t2 * dy, 0 ) : nil
            if ( v1 && v2 )
                if ( ( v1 - ray.from_vec ).length <
                     ( v2 - ray.from_vec ).length )
                    intersection = v1
                else
                    intersection = v2
                end
            elsif ( v1 )
                intersection = v1
            else
                intersection = v2
            end
        end
        intersection
    end
end

class Item

    attr_reader :x, :y, :r, :color

    def initialize( x, y, r, color )
        @x = x
        @y = y
        @r = r
        @color = color
    end
end

class Wall

    attr_reader :x1, :y1, :x2, :y2

    def initialize( x1, y1, x2, y2 )
        @x1 = x1
        @y1 = y1
        @x2 = x2
        @y2 = y2
    end

    def intersect_with_ray( ray )
        intersection = nil
        x0,  y0  = ray.from_vec.x, ray.from_vec.y
        dxr, dyr = ray.to_vec.x - x0, ray.to_vec.y - y0
        dxs, dys = @x2 - @x1, @y2 - @y1
        if ( ( ( dxs * dyr - dys * dxr ) != 0 ) &&
             ( ( dxr != 0 ) || ( dyr != 0 ) ) )
            ts = dxr * ( @y1 - y0 ) + dyr * ( x0 - @x1 )
            ts = ts / ( dxs * dyr - dys * dxr )
            if ( dxr != 0 )
                tr = ( @x1 + ts * dxs - x0 ) / dxr
            else
                tr = ( @y1 + ts * dys - y0 ) / dyr
            end
            if ( ( ts >= 0 ) && ( ts <= 1 ) && ( tr >= 0 ) )
                intersection = Vector.new( self.x1 + ts * dxs, self.y1 + ts * dys )
            end
        end
        intersection
    end
end

class Label

    attr_reader :x, :y, :text

    def initialize( x, y, text )
        @x = x
        @y = y
        @text = text
    end
end

class EnvironmentScale
    def initialize( w=10, h=10, environment=nil )
        @original_width_pixel  = w
        @original_height_pixel = h
        self.environment = environment
    end

    def set_original_size( w, h )
        @original_width_pixel  = w
        @original_height_pixel = h
        init_pixels_per_meter
    end

    def environment=( env )
        @env = env
        init_pixels_per_meter
    end

    def init_pixels_per_meter
        if ( @env )
            pix_per_meter_x = @original_width_pixel  / @env.width
            pix_per_meter_y = @original_height_pixel / @env.height
            @pixels_per_meter = [ pix_per_meter_x, pix_per_meter_y ].min
        end
    end

    def meters_to_pixels( x, y )
        x = x * @pixels_per_meter
        y = @pixels_per_meter * @env.height - ( y * @pixels_per_meter )
        [ x, y ]
    end

    def meter_to_pixel_dist( d )
        d * @pixels_per_meter
    end

    def env_size_in_pixels
        x, y = 0, 0
        if ( @env )
            x = @pixels_per_meter * @env.width
            y = @pixels_per_meter * @env.height
        end
        [ x, y ]
    end

    def zoom_in
        @pixels_per_meter = @pixels_per_meter * 2
    end

    def zoom_out
        @pixels_per_meter = @pixels_per_meter / 2
    end
end

class Environment

    # ITEM_TYPES = [ 'obstacle', 'wall', 'label', 'item' ]
    # ITEM_TYPES.each do |type|
    #     define_method( "add_#{type}" ) do |item|
    #         instance_variable_get( Environment.type_list_name( type ) ) << item
    #     end

    #     define_method( "#{type}_list" ) do
    #         instance_variable_get( Environment.type_list_name( type ) )
    #     end
    # end

    # def Environment.type_list_name( name )
    #     "@#{type}_list"
    # end
    # private_class_method :type_list_name

    attr_reader :width, :height, :obstacle_list, :wall_list, :label_list, :item_list

    def initialize( width=10, height=10 )
        @width  = width  # in meters
        @height = height # in meters

        clear_all
    end

    def clear_all
        # ITEM_TYPES.each do |type|
        #     instance_variable_set( Environment.type_list_name( type ), [] )
        # end
        @obstacle_list = []
        @wall_list = []
        @label_list = []
        @item_list = []
    end

    def add_obstacle( obstacle )
        obstacle_list << obstacle
    end

    def add_wall( wall )
        wall_list << wall
    end

    def add_label( label )
        label_list << label
    end

    def add_item( item )
        item_list << item
    end
end
