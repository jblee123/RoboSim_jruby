require 'optparse'
require 'robot/robot'
require 'robot/behaviors/test_goto'

id = 1
host = 'localhost'
type = 'simulation'
x_pos = 1
y_pos = 1
theta = 0
color = 'blue'
max_vel = -1
max_angular_vel = -1
radius = 0.5

OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on( '-i', '--id ID', Integer, 'Integer ID') do |opt|
        id = opt
    end

    opts.on( '-h', '--host HOST', 'hostname') do |opt|
        host = opt
    end

    opts.on( '-T', '--type TYPE', 'robot type (currently only "simulation" is supported') do |opt|
        type = opt
    end

    opts.on( '-x', '--xpos X_POS', Float, 'robot x position') do |opt|
        x_pos = opt
    end

    opts.on( '-y', '--ypos Y_POS', Float, 'robot y position') do |opt|
        y_pos = opt
    end

    opts.on( '-t', '--theta THETA', Float, 'robot angle') do |opt|
        theta = opt
    end

    opts.on( '-c', '--color COLOR', 'robot color') do |opt|
        color = opt
    end

    opts.on( '-v', '--max_vel MAX_VELOCITY', Float, 'robot max velocity') do |opt|
        max_vel = opt
    end

    opts.on( '-a', '--max_angular_vel MAX_ANGULAR_VELOCITY', Float, 'robot max angular velocity') do |opt|
        max_angular_vel = opt
    end

    opts.on( '-r', '--radius ROBOT_RADIUS', Float, 'robot radius') do |opt|
        radius = opt
    end
end.parse!

r = Robot.new( id=id, host=host, type=type,
               x_pos=x_pos, y_pos=y_pos, theta=theta, color=color,
               max_vel=max_vel, max_angular_vel=max_angular_vel, radius=radius )

r.add_behavior( Behaviors::TestGoto.new )
r.run
puts "robot quitting"
