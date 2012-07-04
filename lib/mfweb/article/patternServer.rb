module Mfweb::Article

class PatternServer
  def initialize path = nil
    @path = path
    @patterns = {}
  end
  def load
    @path.each  do |i| 
      if File.directory? i
        load_dir(i) 
      else
        load_pattern_list_file(i)
      end
    end
    return self
  end
  def load_dir dir
    Dir[File.join(dir, '*.xml')].each do |file|
      xref = MfXml.root(File.new(file))
      name = extract_name xref
      next unless name
      key = File.basename(file, '.xml')
      result = Pattern.new(key, name.text, key + '.html')
      @patterns[result.key] = result
    end
    return self
  end
  def extract_name root
    return case root.name
           when 'pattern'then xpath_only('/pattern/name', root)
           when 'paper'then xpath_only('/paper/title', root)
           else nil
           end
  end
  def load_pattern_list_file filename
    root = MfXml.root(File.new(filename))
    root.xpath("//pattern").each do |e|
      key = e['key']
      url = e.parent['url-root'] + e['url']
      result = Pattern.new(key, e['name'], url)
      @patterns[key] = result
    end                              
  end
  
  def find key
    return @patterns[key] || 
      MissingPattern.new(key, "unable to resolve patternRef: #{key}")
  end

end

class Pattern
  attr_accessor :name, :url, :key
  def initialize key, name, url
    @key, @name, @url = key, name, url
  end
  def missing?
    return false
  end
  def to_s
    "%s at %s" % [@name, @key]
  end
end

class MissingPattern
  attr_accessor :key, :message
  def initialize key, message
    @key, @message = key, message
  end
  def name
    return "Missing Pattern"
  end
  def missing? 
    true
  end
end


end
