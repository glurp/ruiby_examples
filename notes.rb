##################################################################
# notes.rb : several tool for desktop :
#     todo liste
#     writing notes, auto-save
#     curve drawing: copy/paste ascii talled data, plot it/excel/generate png of curve
##################################################################

if Dir.exists?('dsl-gtk')
  require_relative 'dsl-gtk/lib/Ruiby.rb'
else 
  require 'Ruiby'
end
require 'pp'
require 'gnuplot'

$dataName="data_notes/notes.txt"
$todoName="data_notes/todo.txt"
$data={}
$todo=[[true,"eeee","#F00"],[true,"zzzz","#F00"],[false,"dddd","#F00"],[true,"dddd","#F00"]] unless defined?($first)
$active=false unless defined?($first)
$BG="#383838"    # background color window

def loadData()
 if File.exists?($dataName)
    $data=eval File.read($dataName)
 else
    Message.alert("Create an empty database...")
    $data={"title"=> "content..."}
 end
end
def saveData()
 File.write("#{$dataName}.#{(Time.now.to_f*1000).to_i}",$data.inspect)
 File.write($dataName,$data.inspect)

 head='<head><meta http-equiv="content-type" content="text/html; charset=UTF-8" /><style>h2 {background: black;padding: 3px 0px 2px 10px; color: white;} h3 {font-style: bold;}</style></head>'
 data=$data.map {|(name,text)| "<h2>#{name}</h2><p><code><pre>#{text}</pre></code</p>" }.join("<br>")
 data.gsub!(/^\s*\*\s+(.*?)$/,'<li>\1</li>')
 data.gsub!(/([\w\d\s:\_,]+?)\n==+/m,'<h3>\1</h3>')
 html="<html>#{head}<body>#{data}</body></html>"
 File.write("#{$dataName}.html",html)
 #`firefox "#{$dataName}.html"`
 #log "notes.rb : Save done!"
end

loadData()

module Ruiby_dsl 
   def save_current
      if @current && $data[@current]
        $data[@current]=@edit.buffer.text || ""
      end
      #saveData
   end
   def refresh_notes      
      @list.set_data($data.keys)
      if @current && $data[@current]
          cupdate(@current)
      end
   end
   def cupdate(name) 
      @edit.buffer.text=$data[name]
      @list.set_selection($data.keys.index(name))
      @current=name
   end

  ######################################################################
  #                              T o d o list
  ######################################################################
  def todo() 
    if $active
      $active=ask("Already Active ?!") 
      return if $active
    end
    $todo=eval File.read($todoName) if File.exists?($todoName)
    $active=true
    todo1()
  end
  def todo1()
    gtodo=$todo.map {|(stat,text,color)| [stat,text,color,nil]}
    panel_async("Todo list") do |me|
     stack do
       on_delete {
          $todo=gtodo.map {|a|a[0..-2]}
          File.write($todoName,$todo.inspect)
          $active=false  
       }
      gtodo.each do |todo|
          flowi do
            current=current_layout()
            todo[-1]=current
            state,text,color,w=*todo
            buttoni("#famfamfam/arrow_down//Down") {
              idx=gtodo.index(todo)
              if idx<(gtodo.size-1)
                gtodo.insert(idx+1,gtodo.delete_at(idx))
                current.parent.reorder_child(current,idx+1)
              end
            } 
            buttoni("#famfamfam/arrow_up//Up") {
              idx=gtodo.index(todo)
              if idx>0
                gtodo.insert(idx-1,gtodo.delete_at(idx))
                current.parent.reorder_child(current,idx-1)
              end
            } 
            e=nil
            buttoni("#famfamfam/color_swatch",tooltip: "choose color")    {
              if todo[0] 
                c=ask_color() 
                break unless c
                todo[2]=c.to_s
                e.override_background_color(:normal,color_conversion(c))
              end
            }
            e=entry(text,50,width: 420,bg: color) {|v| todo[1]=v}
            buttoni("#edit-delete//delete")    {
               if ask("realy delete '#{todo[1]}' ?")
                 gtodo.delete(todo)
                 delete(current)
               end
            }
            b=buttoni( state ? "#face-smile//Actif" : "#face-smirk//Inactif") { |w|
              todo[0]=!todo[0]
              w.set_image( get_image( todo[0] ? "face-smile" : "face-smirk" ) )
              w.tooltip_text=todo[0] ?  "Actif" : "Inactif"
              color=todo[0] ? todo[2] : "#555"
              e.editable = todo[0]
              e.override_background_color(:normal,color_conversion(color))
            }
            color=todo[0] ? todo[2] : "#555"
            e.editable = todo[0]
            e.override_background_color(:normal,color_conversion(color))
          end       
      end
      flow {
        button("Create a new task...") {
          t=promptSync("Text ?")
          $todo=gtodo.map {|a|a[0..-2]}
          $todo<< [true,t||"","#A00"] ; me.destroy; after(0) {todo1()}
        }      
        buttoni("#call-stop//Close") { 
          $todo=gtodo.map {|a|a[0..-2]}
          File.write($todoName,$todo.inspect)
          $active=false
          me.destroy 
        }
      }
     end
    end

  end
  ######################################################################
  #                              N o t e s
  ######################################################################
  def doit()
    if $active
      $active=ask("Already Active ?!") 
      return if $active
    end
    @panel=panel_async("Notes") do |me|
     stack do
         on_delete { 
            save_current
            saveData
            $active=false
         }
        flow { 
            flowi { 
              @list=list("Items",100,200) {|li| 
                save_current
                if li && li.size>0
                  @current=$data.keys[li.first] 
                  @edit.buffer.text=$data[@current]
                end
              }
            }
            stack {
              flowi {
               flowi {
               button('#document-save//save') do
                    save_current
                    saveData
               end
               button('#applications-graphics//rename') do
                  prompt("name") { |name|
                    if name && name.size>0
                       save_current
                       $data[name]=$data[@current]
                       $data.delete(@current)
                       saveData
                       @current=name
                       refresh_notes
                    end
                  }
               end
               }
               space(1)
                buttoni('#edit-delete//delete this note') do
                save_current
                if $data[@current].strip.size<3 || ask("delete note '#{@current}', size= #{@edit.buffer.text.size} ?")
                  $data.delete(@current) 
                  @current=$data.first
                  refresh_notes
                end
               end
              }
             separator
             @edit=source_editor(lang: "markdown").tap {|w| w.width_request=800}.editor
            }
        }
        separator
        flowi {
           flowi {
               button("#document-save//save all") do
                    save_current
                    saveData
               end
               button("#window-new//create new theme")do
                  prompt("name","") { |name|
                    save_current
                    $data[name]=""
                    refresh_notes
                  }
               end           
           }
           space
           flowi { 
             button("#call-stop//Close") { 
              save_current
              saveData
              me.destroy 
              $active=false
            }
           }
        }
     end
     $active=true
     refresh_notes
    end # end dialog
  end # end def
end # module

  ######################################################################
  #                              C U R V E S
  ######################################################################

module Ruiby_dsl 
  def doCurves()
    @panelc=panel_async("Courbes") do |me|
     stack do
       flow {
         @ce=sloti(source_editor(lang: "markdown")).tap {|w| w.width_request=400}.editor
         @cv=source_editor(lang: "markdown").tap {|w| w.width_request=200}.editor
         @cv2=source_editor(lang: "markdown").tap {|w| w.width_request=200}.editor
       }
       flowi {
         buttoni("T") { @ce.buffer.text=File.read("meteo_data.csv") } 
         buttoni("A") { @ce.buffer.text=(0..10).each_with_object(0).map {|i,s| s=s+rand(1..10); a=s+rand(1..20); [s,a].join(";")}.join("\n") } 
         label "separator :"; @e1=entry('[;\s:\\-T]') 
         separator
         label "columns :"; @e2=entry("0 1")
         buttoni("Go") { showcurce(:win) }
         buttoni("Export") { load(__FILE__); showcurce(:excel) }
       }
     end
    end
  end
  def showcurce(dst)
     split=@e1.text
     columns=@e2.text
     t=@ce.buffer.text.each_line.map {|line| line.strip.chomp.split(/#{split}/) }
     @cv.buffer.text=t.map {|a| "<"+a.join(">\t<")+">" }.join("\n") 
     lcols=columns.split(/\s+/).map {|a| a.to_i}
     if dst==:win
       @cv2.buffer.text=t.map {|a| lcols.map {|c| a[c]}.join("\t") }.join("\n") 
       max=0
       content=t[0..4].map {|l| max<l.size ? max=l.size : 0;l}.
                      map {|l| (l << 0) while l.size<max ; l}.
                      transpose.
                      each_with_index.map {|a,i| "C%3d => %s" % [i,a.join("\t")]}.join("\n")
       dialog { t=text_area 800,300;  t.text=content }
     else
       fn_csv="d:/temp/a#{Time.now.to_i%1000}.csv"
       content=t.map {|a| lcols.map {|c| a[c]}.join(";") }.join("\n") 
       File.write(fn_csv,content)
       show_curve(t.each_with_index.map {|a,i| [i+1]+lcols.map {|c| a[c].to_f} }, fn_csv)
     end
  end
  
  # data= [[index,v1,v2...],row2,row3...]
  def show_curve(data,fn_csv)
    ctx=panel("Type de courbes") { |dia,ctx|
      ctx[:type]="y1=f(t),y2=f2(t)"
      stack {
        label "Nombre de lignes : #{data.size}"
        label "Nombre de mesures : #{data.first.size-1}"        
        separator
        label "y >> y pixel curve"
        label "t: index echant"
        label "f1: first mesure"
        label "fi= i eme mesure"
        separator
        stacki {
          button("y1=f1(t),y2=f2(t)") { ctx[:type]="y1=f(t),y2=f2(t)" ; dia.response(1)}
          button("xi,yi=f1,fi")       { ctx[:type]="xi,yi=f1,fi"      ; dia.response(1)} if data.first.size>2
          button("timing")       { ctx[:type]="timing"      ; dia.response(1)}
        }
      } 
    }
    filename="d:/temp/plot#{Time.now.to_i%1000}.png"
    File.delete(filename) if File.exists?(filename)
    
    datax,*ydata=(0..(data.first.size-1)).map {|nocol| data.map {|row|  row[nocol]} } # index,serie1,serie2...
    # datax >> index lignes
    # ydata >> [serie1,serie2...]
    
    if ctx[:type]=="timing"
      ctx[:type]="xi,yi="
      ydata=convers_in_timing(ydata)
      alert ydata
    end
    Gnuplot.open do |gp| Gnuplot::Plot.new( gp ) do |plot|  
        plot.output filename
        plot.terminal "png"
        plot.title  "Courbes"
        
        case ctx[:type]
        when /^y1=/
          minmax=ydata.first[1..-1].minmax.tap {|(a,b)| d=(b-a) ; [a-d/10,b+d/10]}.tap {|(a,b)| [(a-1).to_i, (b+1).to_i]}
          plot.yrange   "[#{minmax.join(':')}]"
          i=1
          plot.data = ydata.map do |y| 
            Gnuplot::DataSet.new( [datax,y] ) do |ds|
              ds.with = "lines"
              ds.title = y[0]=~/\w+/ ? y[0] : "data#{i}"
              ds.linewidth=2
              i+=1
          end end
        when /^xi,yi=/
          datax,*ydata=*ydata
          plot.data = ydata.map { |y| 
          i=1
          Gnuplot::DataSet.new( [datax,y] ) do |ds|
            ds.with = "lines"
            ds.title = y[0]=~/\w+/ ? y[0] : "data#{i}"
            ds.linewidth=2
            i+=1
          end }
        end
    end end
      if File.exists?(filename)
        dialog("#{filename} #{File.size(filename)/1000} KB ; at #{File.mtime(filename)}") { 
          buttoni("Vue sous Excel...") { Thread.new { 
              system('c:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE',fn_csv) rescue error($!)
            }
          }
          image(filename) 
        }
      else
        alert("no file png! #{filename}")
      end
    end
  def convers_in_timing(ydata)
      if ydata.first.each_cons(2).select {|(a,b)| a>b}.size>0 # delta time
        s=0
        data=ydata.first.map {|v| s+=v ; s}
      else                                                     # absolute time/duration
        data=ydata.first
        iv=data.first
        data.map! {|v| v - iv }
      end
      y0=100
      deltay=y0/data.size
      x0=data.first
      data=data.each_with_index.map {|v,i| y=y0-i*deltay ; x=v-x0 ; [x,y]}.map {|(x,y)| [[x,0],[x,y],[x,0]]}.flatten(1)
      ydata=[[],[]]
      data.each {|(a,b)| ydata.first << a ; ydata.last << b}
      ydata
  end
end

unless defined?($first)
  Ruiby.app width: 50,height: 1, title: "Notes" do
    chrome(false);
    set_window_icon "d:/usr/icons/vrac/books_03.png"
    systray(1000,0, icon: "d:/usr/icons/vrac/books_03.png") {}
    $app=self
    @chrome=false
    set_default_size(0,0)
    resize(30,10)
    rposition(20,900)
    stack {
      flowi { 
        button("#famfamfam/text_list_bullets") {load(__FILE__);todo}
        button("#famfamfam/table") {load(__FILE__);doit}
        button("#famfamfam/chart_curve") {load(__FILE__);doCurves}
      }
    }
    def_style <<EEND
.tooltip {
   background-color: #FF0000;
   color: #0000FF;
   padding: 100px;
}
EEND
  end
  $first=false
end