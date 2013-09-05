include Java

require 'console/robo_sim_canvas'
java_import javax.swing.JFrame
java_import java.awt.GridBagLayout
java_import java.awt.GridBagConstraints
java_import java.awt.Insets
java_import java.awt.Toolkit

class RoboSimFrame < JFrame

    def initialize( the_app )
        super "Robo Sim"
        init( the_app )
    end

    def init( the_app )

        @the_app = the_app

        screen_size = Toolkit.getDefaultToolkit.getScreenSize
        w = screen_size.getWidth - 100
        h = screen_size.getHeight - 100
        setSize w, h

        @scale = EnvironmentScale.new( w, h, the_app.environment )

        self.getContentPane.setLayout( GridBagLayout.new )

        @canvas = RoboSimCanvas.new( the_app.environment, the_app.simulator, @scale )
        @canvas.setLayout nil
        self.getContentPane.add( @canvas,
                                 GridBagConstraints.new( 0, 0, 1, 1, 1.0, 1.0,
                                                         GridBagConstraints::CENTER,
                                                         GridBagConstraints::BOTH,
                                                         Insets.new( 0, 0, 0, 0 ),
                                                         0, 0 ) )

        addKeyListener FrameKeyListener.new( the_app )
        addWindowListener FrameWindowListener.new( the_app )

        setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
        setLocationRelativeTo nil
        setVisible true
    end

    def switch_paused
        self.app_instance.communicator.send_switch_pause()
    end

    class FrameKeyListener < java.awt.event.KeyAdapter

        def initialize( the_app )
            super()
            @the_app = the_app
        end

        def keyPressed( e )
            if ( e.getKeyCode == java.awt.event.KeyEvent::VK_P && !e.isShiftDown )
                @the_app.communicator.send_switch_pause
            end
        end
    end

    class FrameWindowListener < java.awt.event.WindowAdapter

        def initialize( the_app )
            super()
            @the_app = the_app
        end

        def windowClosing( e )
            puts "should be initiating shutdown"
            @the_app.initiate_shutdown
        end
    end
end
