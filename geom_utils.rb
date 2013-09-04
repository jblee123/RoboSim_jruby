module GeomUtils

DEG_PER_CIRCLE = 360.0

def GeomUtils.deg_to_rad( deg )
    deg * ( ( 2 * Math::PI ) / DEG_PER_CIRCLE )
end

def GeomUtils.rad_to_deg( rad )
    rad * ( DEG_PER_CIRCLE / ( 2 * Math::PI ) )
end

def GeomUtils.normalize_angle( angle )
    angle += DEG_PER_CIRCLE while angle < 0
    angle -= DEG_PER_CIRCLE while angle >= DEG_PER_CIRCLE
    angle
end

def GeomUtils.avg_angles( a1, a2 )
    if ( a1 - a2 ).abs <= ( DEG_PER_CIRCLE / 2 )
        (a1 + a2) / 2.0
    else
        normalize_angle( ( a1 + a2 + DEG_PER_CIRCLE ) / 2.0 )
    end
end

def GeomUtils.angle_diff( a1, a2 )
    diff = ( a1 - a2 ).abs
    ( diff <= ( DEG_PER_CIRCLE / 2 ) ) ? diff : ( DEG_PER_CIRCLE - diff )
end

class Vector

    attr_reader :x, :y, :z
    #attr_writer :x, :y, :z

    def initialize( x=0, y=0, z=0 )
        @x, @y, @z = x.to_f, y.to_f, z.to_f
    end

    def dup()
        Vector.new( x, y, z )
    end

    def to_s
        sprintf( "[%.02f, %.02f, %.02f]", x, y, z )
    end

    def ==( other )
        !!other &&
            ( ( x == other.x ) &&
              ( y == other.y ) &&
              ( z == other.z ) )
    end

    def +( other )
        Vector.new( x + other.x, y + other.y, z + other.z )
    end

    def -( other )
        Vector.new( x - other.x, y - other.y, z - other.z )
    end

    def *( num )
        Vector.new( x * num, y * num, z * num )
    end

    def /( num )
        Vector.new( x / num, y / num, z / num )
    end

    def rotate_z( degs )
        rads = GeomUtils.deg_to_rad( degs )
        c = Math.cos( rads )
        s = Math.sin( rads )
        x = @x
        y = @y
        new_x = x * c - y * s
        new_y = x * s + y * c
        Vector.new( new_x, new_y, z )
    end

    def angle
        GeomUtils.normalize_angle( GeomUtils.rad_to_deg( Math.atan2( y, x ) ) )
    end

    def length
        Math.sqrt( x**2 + y**2 + z**2 )
    end

    def get_unit
        l = length
        ( l == 0 ) ? Vector.new( 1, 0, 0 ) : ( self / l )
    end

end # of Vector

class Ray

    attr_reader :from_vec, :to_vec

    def initialize( from_vec=nil, to_vec=nil )
        @from_vec = from_vec && from_vec.dup
        @to_vec = to_vec && to_vec.dup
    end

    def intersect_with_circle( xc, yc, r )
        intersection = nil
        x0, y0 = @from_vec.x, @from_vec.y
        dx, dy = @to_vec.x - x0, @to_vec.y - y0
        a = dx**2 + dy**2
        b = 2 * ( x0 * dx - xc * dx + y0 * dy - yc * dy )
        c = x0**2 + xc**2 - 2 * x0 * xc + y0**2 + yc**2 - 2 * y0 * yc - r**2
        quot = b**2 - 4 * a * c
        if ( quot >= 0 )
            t1 = ( -b + Math.sqrt( quot ) ) / ( 2 * a )
            t2 = ( -b - Math.sqrt( quot ) ) / ( 2 * a )
            v1 = ( t1 >= 0 ) ? Vector.new( x0 + t1 * dx, y0 + t1 * dy, 0 ) : nil
            v2 = ( t2 >= 0 ) ? Vector.new( x0 + t2 * dx, y0 + t2 * dy, 0 ) : nil
            if ( v1 && v2 )
                if ( ( v1 - @from_vec ).length() <
                     ( v2 - @from_vec ).length() )
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


    def intersect_with_segment( xs0, ys0, xs1, ys1 )
        xs0 = xs0.to_f
        ys0 = ys0.to_f
        xs1 = xs1.to_f
        ys1 = ys1.to_f
        intersection = nil
        x0,  y0 = @from_vec.x, @from_vec.y
        dxr, dyr = @to_vec.x - x0, @to_vec.y - y0
        dxs, dys = xs1 - xs0, ys1 - ys0
        if ( ( ( dxs * dyr - dys * dxr ) != 0 ) &&
             ( ( dxr != 0 ) || ( dyr != 0 ) ) )
            ts = dxr * ( ys0 - y0 ) + dyr * ( x0 - xs0 )
            ts = ts / ( dxs * dyr - dys * dxr )
            if ( dxr != 0 )
                tr = ( xs0 + ts * dxs - x0 ) / dxr
            else
                tr = ( ys0 + ts * dys - y0 ) / dyr
            end
            if ( ( ts >= 0 ) && ( ts <= 1 ) && ( tr >= 0 ) )
                intersection = Vector.new( xs0 + ts * dxs, ys0 + ts * dys )
            end
        end
        intersection
    end
end # of Ray
end # of Robosim::GeomUtil
