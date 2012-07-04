module Mfweb::Article

#======== Bibliography ==========================
# Holds data to support generating a bibliography

# At the moment reads data from the supplied bibliography file and
# puts in hyperlinks to books and urls in the bibliography.

class Bibliography
  def initialize file = nil
    @entries = {}
    load_file file if file
  end
  def load_file file
    if FileTest.exists? file
      root =  MfXml.root(File.new(file))
      root.xpath('//ref').each {|e| load_bib_entry e}
    else
      puts $deferr, "Unable to find bibiography file: " + file
    end
  end
  def load_bib_entry aRefElement
    ref = BibRef.new
    ref.name = aRefElement['name']
    ref.text = aRefElement['text']
    ref.isbn = extractIsbn aRefElement
    ref.url = element_text(aRefElement.xpath('.//url').first)
    ref.cite = element_text(aRefElement.xpath('cite').first)
    @entries[ref.name] = ref 
  end
  def element_text anElement
    return anElement ? anElement.text : nil
  end
  def extractIsbn aRefElement
    book_elem = aRefElement.xpath('book').first
    if book_elem
      return book_elem.xpath('isbn').first.text
    else
      isbn_only = aRefElement.xpath('isbn').first
      return isbn_only ? isbn_only.text : nil
    end
  end
  def size
    @entries.size
  end
  def loaded?
    return ! @entries.empty?
  end
  def [] arg
    $stderr.puts "Bibilography not loaded" unless self.loaded?
    result = @entries[arg]
    result ? result : NullBibRef.new(arg)
  end
end

class BibRef
  attr_accessor :name, :isbn, :text
  def initialize
    @url = nil
  end
  def url
    return @url if @url
    return 'http://www.amazon.com/exec/obidos/ASIN/' + @isbn if @isbn
  end
  def url= arg
    @url = arg
  end
  def null?
    false
  end
  def cite
    return @cite ? @cite : "[#{name}]"
  end
  def cite= arg
    @cite = arg
  end
end
class NullBibRef < BibRef
  def null?
    return true
  end
  def initialize arg
    raise "No name passed in call to Bib Server" unless arg
    @name = arg
  end
  def name
    puts 'missing bib reference for : ' + @name
    return '** missing ' + @name
  end
  def url
    nil
  end
end

end
