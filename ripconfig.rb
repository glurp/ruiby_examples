require_relative 'utils'
require_relative 'dsl-gtk/lib/Ruiby.rb'

=begin
Configuration IP de Windows

   Nom de l'h?e . . . . . . . . . . : D-CZH01404CV
   Suffixe DNS principal . . . . . . : 
   Type de noeud. . . . . . . . . .  : Hybride
   Routage IP activ . . . . . . . . : Oui
   Proxy WINS activ . . . . . . . . : Non
   Liste de recherche du suffixe DNS.: localdomain

Carte Ethernet Connexion au róeau local :

   Suffixe DNS propre Šla connexion. . . : 
   Description. . . . . . . . . . . . . . : Realtek PCIe GBE Family Controller
   Adresse physique . . . . . . . . . . . : 40-61-86-C5-CD-FE
   DHCP activ® . . . . . . . . . . . . . : Non
   Configuration automatique activå. . . : Oui
   Adresse IPv4. . . . . . . . . . . . . .: 10.97.70.240(præò© 
   Masque de sous-róeau. . . .?? . . . : 255.255.255.0
   Adresse IPv4. . . . . . . . . . . . . .: 10.97.137.240(præò© 
   Masque de sous-róeau. . . .?? . . . : 255.255.255.0
   Adresse IPv4. . . . . . . . . . . . . .: 10.203.76.160(præò© 
   Masque de sous-róeau. . . .?? . . . : 255.255.252.0
   Adresse IPv4. . . . . . . . . . . . . .: 192.168.213.222(præò© 
   Masque de sous-róeau. . . .?? . . . : 255.255.255.0
   Passerelle par dæaut. . . .?? . . . : 10.203.79.254
   Serveurs DNS. . .  . . . . . . . . . . : 10.159.66.68
   NetBIOS sur Tcpip. . . . . . . . . . . : Activ

Carte róeau sans fil Connexion au róeau local* 2??
   Statut du mäia. . . . . . . . . . . . : Mäia dãonnect
   Suffixe DNS propre Šla connexion. . . : 
   Description. . . . . . . . . . . . . . : Microsoft Wi-Fi Direct Virtual Adapter
   Adresse physique . . . . . . . . . . . : 70-F1-A1-3E-2E-38
   DHCP activ® . . . . . . . . . . . . . : Oui
   Configuration automatique activå. . . : Oui

Itinéraires actifs :
Destination réseau    Masque réseau  Adr. passerelle   Adr. interface Métrique
          0.0.0.0          0.0.0.0    10.203.79.254     10.97.70.240     30
          8.0.0.0        255.0.0.0      192.168.2.1     10.97.70.240     26
       10.97.70.0    255.255.255.0         On-link      10.97.70.240    281
     10.97.70.240  255.255.255.255         On-link      10.97.70.240    281
     10.97.70.255  255.255.255.255         On-link      10.97.70.240    281
      10.97.137.0    255.255.255.0         On-link      10.97.70.240    281
    10.97.137.240  255.255.255.255         On-link      10.97.70.240    281
    10.97.137.255  255.255.255.255         On-link      10.97.70.240    281
      10.203.76.0    255.255.252.0         On-link      10.97.70.240    281
    10.203.76.160  255.255.255.255         On-link      10.97.70.240    281
    10.203.79.255  255.255.255.255         On-link      10.97.70.240    281

=end

def mp(*t)  puts t.map {|a|a.kind_of?(String) ? a : a.inspect}.join(", ") end

$hconfig={}
$h={}
$title=nil
`ipconfig /all`.each_line {|line| line.chomp!
 next if line.strip.size==0
 if line =~ /^[A-Z]\w+/
   $hconfig[$title]=$a if $title && $a.size>0 
   $title=line
   $a=[]
 else
   k,v=line.strip.split(/:/)
   $a << [k,v] if k !~ /===/
 end
}
$hconfig[$title]=$a if $title
nb=0
default="?"
$route=`route print`.each_line.each_with_object([]) do |line,ares| line.chomp!
 next if line.strip.size==0
 nb+=1 if line =~ /=========/
 next if nb>=4

 a=line.strip.split(/\s+/)

 if a.first =~ /\.0$/  
   ares << [a[0],a[2]=="On-link" ? "IF-gateaway" :  a[2] ,a[3]]
 end
end

def bold(v) a=(v =~ /\d+\.\d+\.\d+\.\d+/ ? "bold" : "") ; mp a,v ; a end 

$w=700
$h=60
Ruiby.app({width: $w, height: $h, title: "Ifconfig2"}) do
  move(100,100)
  class << self
    alias obutton button
    def button(text,style={},&b)
        w=obutton(text,style,&b)
        w.set_alignment(0.0, 1.0)
        w
    end
  end
  laddr=$hconfig.each_with_object([])  do |(k,ll),laddr| 
    ll.each  {|(name,value)|   laddr << [value,k] if name =~ /IPv4/i }
  end

  stack do
   accordion do
      $hconfig.each do |k,ll| 
          aitem("#{k}...") do
            table(0,0) do
             ll.each {|name,value|  row { 
                cell_right(label("#{name} :",font: "courier new 10"))
                cell_left(label(value,font: "courier new #{bold(value)} 10")) 
             } }
            end
          end
      end
      aitem("Recap...") do
          table(0,0) do
             laddr.each {|(ip,cat)| row {
                cell_right(label("#{ip} :",font: "courier new bold 10"))
                cell_left(label(cat,font: "courier new 10")) 
             } }
          end
          table(0,0) do
               $route.each {|ip,to,via| row {
                cell_right(label("#{ip}",font: "courier new bold 10"))
                cell_left(label(" to gateway :",font: "courier new 10")) 
                cell_left(label("#{to}",font: "courier new bold 10"))
                cell_left(label(" by interface :",font: "courier new 10")) 
                cell_left(label(via,font: "courier new 10")) 
               } }
          end
       end
    end
    flowi do
       buttoni("Route...") {  exec2log("route", "print") }
       buttoni("Ping...") { prompt("Adresse ?","10.203.76.") {|t|  exec2log("ping",t)  } }
       buttoni("tracert...") { prompt("Adresse ?","") {|t|  exec2log("tracert",t) } }
       space()
       labeli(Time.now.strftime('%T'))
    end
  end
  def exec2log(*t)
    log "#{t.join(' ')} ..."
    after(1) {
     Thread.new { IO.popen(t) {|f| 
        (a=f.gets.chomp ;gui_invoke_wait { log(a) }) until f.eof? 
     } }
    }
  end
 def_style <<'EEND'
    button { padding: 0px 0px 0px 0px    ; background-color: #AFF;  } 
    button label {padding: 0px 0px 0px 0px ;background-color: #CCC; color: #400; }
EEND
end