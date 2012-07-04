module Mfweb::Article

class FootnoteServer
  def initialize filename = nil
    @references = []
    @notes = {}
    load_file filename if filename
  end
  def load_file file
    if FileTest.exists? file
      root =  MfXml.root(File.new(file))
      load_doc root
    else
      puts $deferr, "Unable to find footnote file: " + file
    end
  end

  def load_doc root
    root.xpath('//footnote').each {|f| load_footnote f}
  end

  def load_footnote anElement
    footnote = Footnote.new(anElement)
    @notes[footnote.key] = footnote
  end

  def record key
    @references << key unless @references.include? key
  end

  def references
    @references
  end

  def render_reference key
    "<a href = '#%s'>[%s]</a>" % [anchor(key), marker(key)]
  end

  def anchor key
    "footnote-" + key
  end

  def marker key
    @references.index(key) + 1
  end

  def head key
    raise "No footnote with key: <#{key}>" unless @notes[key]
    return @notes[key].head
 end

  def body key
    @notes[key].body
  end
end

class Footnote 
  def initialize anElement
    @element = anElement
  end

  def simple?
    @element.css('H').empty?
  end

  def head
    @element.xpath('H').first
  end

  def key
    return @element['key']
  end
  
  def body
    simple? ? @element.children :
      @element.elements.reject{|e| "H" == e.name }
  end
  
  def to_s
    "%s" % key
  end
end

#TODO there seems to be a spurious <H> in the html output
# should fix and check for XHTMLness in some tests


end
