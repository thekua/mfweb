module Mfweb::Core
require 'uri'
module HtmlUtils
  def a_ref uri, text
     "<a href = #{URI.encode(uri)}>#{text}</a>"
  end
  def self.dot_sep
    "&nbsp;&middot; "
  end
  def dot_sep
    HtmlUtils::dot_sep
  end
  def include fileName
    include_path.each do |dir|
      f = File.join(dir, fileName)
      return include_abs(f) if File.exists? f
    end
    raise "unable to find #{fileName} in #{include_path.join(' ')}"
  end
  def include_abs fileName
    case File.extname(fileName)
    when ".html" then File.read(fileName)
    when ".markdown"
      require 'kramdown'
      mdown = ERB.new(File.read(fileName)).result(binding)
      Kramdown::Document.new(mdown).to_html
    when ".haml"
      require 'haml'
      Haml::Engine.new(File.read(fileName)).render(self)
    else 
      raise "unable to include #{fileName}"
    end
  end
  def include_path
    %w[. .. ../../gen gen]
  end

  def custom_banner args
    photo_fn = args[:photo_fn] || 'banner.png'
    output = StringIO.new
    template_file = File.join(site_root, 'gen/banner.html.erb')
    output << ERB.new(File.read(template_file)).result(binding)
    return output.string
  end

  def site_root
    Dir.pwd
  end

  def pick_photo arg
    tags = Array(arg)
    m = lambda {|regexp| tags.any? {|t| t.match(regexp)}}
    return case
           when m.call(/noSQL/), m.call(/database/)
             '../img/mesa.png'
           when m.call(/refactoring/) then '../img/tate.png'
           when m.call(/domain specific language/) 
             '../img/ironbridge.jpg'
           when m.call(/bad thing/) then '../img/croc.png'
           when m.call(/agile/) then '../img/poetta.png'
           when m.call(/extreme programming/) then '../img/poetta.png'
           when m.call(/design/) then '../img/zakim.png'
           when m.call(/architecture/) then '../img/zakim.png'
           else 'banner.png'
           end
  end




  # def generate_line width
  #   # handy for trying out text line widths
  #   num_alphabets = width / 26 + 1
  #   base = []
  #   num_alphabets.times {base += ('a'..'z').to_a}
  #   return base[0..width]
  # end

  def amazon isbn, text
#    "** amazon link **"
    %[<a href = "http://www.amazon.com/gp/product/#{isbn}?ie=UTF8&tag=martinfowlerc-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=#{isbn}">#{text}</a><img src="http://www.assoc-amazon.com/e/ir?t=martinfowlerc-20&l=as2&o=1&a=0321601912" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;"/>]
  end
end

  def css fileName
    %[<link href = "#{fileName}" rel = "stylesheet" type = "text/css"/>]
  end
end
