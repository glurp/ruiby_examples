# encoding: utf-8
require 'gtk3'
#require 'Ruiby'
require_relative 'dsl-gtk/lib/ruiby.rb'
$th=nil

def doQuery(form,w)
  $th.kill if $th
  $th=nil
  w.text_area.wrap_mode=:none
  form=form.each_with_object({}) {|(k,w),fv| fv[k]= w.text}
  if form[:nm].size>0
    regex_not=Regexp.new("("+(form[:nm].split(/\s+/)).join(")|(")+")")  
  else
    regex_not=nil
  end
  lmots=form.keys.grep(/^s\d$/).map { |w| form[w].split(/\s+/) }.reject {|l| l.size==0}
  return if lmots.size==0
  lregexp= lmots.map { |l| Regexp.new("("+l.join(")|(")+")") }
  w.text="Start...\n"
  Ruiby.stock_put("dico",form)
  $th=Thread.new {
    Dir[form[:rep]+"/"+form[:fn]].each { |entry|
      next if Dir.exists?(entry)    
      res=File.read(entry).split(/\r?\n/).select { |line|  (!regex_not || ! regex_not.match(line)) && lregexp.all? {|re| re.match(line)} }
      gui_invoke_wait { res.each {|l| w.append("%-20s | %-s\n" % [File.basename(entry),l.strip]) } } if res.size>0
    }
    gui_invoke { w.append("\nend.\n") }
  }
end

def export(data)
 content=data.split(/\r?\n/)[1..-2].join("\n")
 filename=ask_file_to_write(".","*.log")
 return unless filename
 File.open(filename,"w") { |f| f.write(content) }
 system("vim",filename) if ask("Export Done !\n view it?")
end

def help
 txt= <<EEND
Date/Durée :
===========
   01/02/2013  -2j  >>> 20 Janvier et 1 Fevrier 2013
   01/02       +2j  >>> 1 Fevrier  et 2 Fevrier <année courante>
   ""       -02:30  >>> 150 dernieres minutes
   ""       -2h     >>> 2 dernieres heures
   ""       -2j     >>> aujourd''hui et hier
   ""       -1m     >>> mois courant
   ""       ""      >>> tous !
Repertoire/fichiers
===================
  reperoires des log (recursivement) et filtre sur les noms de fichier
  /var/log  *.log
  /var/log  x*.log

Recherche de caracteres/mot
===========================
Exemples:
 ncm:   A B C
 camm:  a b c
 ecamm: d e
 >>> not (A ou B ou C) AND (a ou b ou c) AND (d ou e)
 
 camm:  a b c
 >>> (a ou b ou c) 
EEND
 edit(txt)
end

Ruiby.app width:800,height: 700,title: 'SGrep' do
 @form={}
 p last=Ruiby.stock_get("dico",{db:"",df:"",rep:"",fn:"",nm:"",s1:"",s2:"",s3:"",s4:"",s5:""})
 stack do
    framei("Parametres") do
        stack {
          flowi {label("Saisir les parametres de recherches"); buttoni("#help") { help }; }
          framei("Dates") {
            flow { 
              labeli("debut/fin : ") ; @form[:db]=entry(last[:db]) 
              labeli("duree +/- : ") ; @form[:df]=entry(last[:df]) 
            }
          }
          table(2,4) do
            row {  cell_right(label("Repertoire : ")) ; cell(@form[:rep]=entry(last[:rep]))}
            row {  cell_right(label("Fichiers : "))   ; cell(@form[:fn]=entry(last[:fn]))  }
            row {  cell_right(label("ne contenant pas un des mots : ")) ; cell(@form[:nm]=entry(last[:nm]))}
            %w{s1 s2 s3 s4 s5}.each do |s|
              row {  cell_right(label("et contenant au moins un des mots: ")) ; cell(@form[s.to_sym]=entry(last[s.to_sym]))}
            end
          end
          buttoni(" Validation ") { doQuery(@form,@ta) } 
        }
    end
    @ta=text_area(200,200,{font: 'Courier 12'})
    flowi { button("Export") {  export(@ta.text) } ; button("Exit") { exit!(0) } }
 end
end
