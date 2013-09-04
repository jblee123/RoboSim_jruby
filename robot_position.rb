require 'geom_utils'

class RobotPosition

    attr_reader :location, :heading
    attr_writer :location, :heading

    def initialize( location=nil, heading=0 )
        @location = location
        @heading  = heading
    end

    def to_s
        "[#{@location}, #{@heading}]"
    end

    def dup
        RobotPosition.new( @location, @heading )
    end
end
