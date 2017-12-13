require_relative 'dsl-gtk/lib/Ruiby.rb'
 Ruiby.app width: 1900, height: 1200, title: "-B L A N C-" do 
  move(0,0)
  chrome(false)
  this=self
  a=0
  @niv=1.0
  @blue=0.0
  @pos=[-1,-1]
  stack do
      @cv=canvas(1900,1200) {
       on_canvas_button_press {|w,e| 
        if e.y<=200
          ask("Iconifier ?") && this.iconify() || (ask("exit?") && ruiby_exit)
        end
        [e.x,e.y]
       } 
       on_canvas_button_motion {|w,e,o| 
        l,h=w.size_request()
        @niv=e.y/(h-200.0) if e.y>200
        @blue=1.0*e.x/l if e.y>200
        a=0
        @pos=[e.x,e.y]
        [e.x,e.y]
       }
       on_canvas_draw {
         niv=[0,255,(@niv*256).round].sort[1]
         b=[0,255,(niv*@blue).round].sort[1]
         coul= "#%02X%02X%02X" % [niv,niv,b]
         @cv.draw_rectangle(0,0,*size(),3,"#AAA",coul,3)
         @cv.rotation(1000,600,3.14*a/180.0) { @cv.draw_text_center(0,0,"( ^ | ^ )",10.0,"#EEE") }
         if @pos[0]>=0 && @pos[1]>=0
           @cv.draw_circle(@pos.first,@pos.last,5,"#AAA","#000",0)
         end
       }
      }
  end
  anim(70) { a=(a+0.02)%360 ; @cv.redraw}
 end 
