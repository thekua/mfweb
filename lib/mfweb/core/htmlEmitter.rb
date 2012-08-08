module Mfweb::Core
# pumps output in html form. Uses a simple string output, not 
# anything more fancy.

require 'delegate'

class HtmlEmitter
  SPAN_ELEMENTS = %w[i b a code img th td]
  def initialize output = ""
    @out = output
  end
  attr_reader :out
  def close
    @out.close
  end
	def HtmlEmitter.open fileName, &block
    File.open(fileName, 'w') do |out|
      yield self.new(out)
    end
  end
  def element(name, attributes=nil, isInline=true, &block)
    #ignores isInline arg which is kept for compatability
    if SPAN_ELEMENTS.include? name
      element_span name, attributes, &block
    else
      element_block name, attributes, &block
    end
  end
  def element_block(name, attr = nil, &block)
    raw_element name, attr, false, &block
  end
  def element_span(name, attributes = nil, &block)
    raw_element name, attributes, true, &block
  end
  def raw_element(name, attributes, isInline)
    @out << "\n" unless isInline
    @out <<  "<#{name}"
    print_attributes(attributes) unless nil == attributes
    @out << ">"
    yield if block_given?
    @out << "</#{name}>"
    @out << "\n" unless isInline
  end
  def print_attributes attributes
    #TODO 1.9 I think I can remove the to_s
    attributes.sort{|a,b| a[0].to_s <=> b[0].to_s}.each do |key, value| 
      @out << " #{key} = '#{substituteXmlEntities(value.to_s)}'"
    end
  end
  def html(&block)
    element_block "html", nil, &block
  end
  def head(&block)
    element_block "head", nil, &block
  end
  def title(text)
    element_block("title") {@out << text}
  end
  def body(&block)
    element_block "body", {}, &block
  end
  def jquery
    js 'http://code.jquery.com/jquery-1.6.2.min.js'
  end
  def js uri
    element_block 'script', {:type => 'text/javascript', 
      :src => uri}
  end
  def text arg
    @out <<  arg if arg
  end
  def << arg
    @out << arg 
  end
  def cdata arg
    @out << substituteXmlEntities(arg)
  end
  def substituteXmlEntities aString
    result = aString.gsub "&", "&amp;"
    result.gsub! "<", "&lt;"
    return result
  end
  def p(css_class = nil, &block)
    attr = class_attr css_class
    element_block "p", attr, &block
  end
  def h(level, attr = nil, &block)
    element_block("h" + level.to_s, attr, &block)
  end

  def hr css_class = nil
    attr = class_attr css_class
    element_span('hr', attr) {}
  end

  def a_ref(href, &block)
    if href
      element_span("a", {'href' => href}, &block)
    else
      yield
    end
  end

  def a_name(name) 
    element_block('a', {'name' => name}) {}
  end

  def b(&block)
    element_span 'b', nil, &block
  end

  def i(&block)
    element_span 'i', nil, &block
  end

  def span css_class, &block
    attr = class_attr css_class   
    element_span 'span', attr, &block
  end

  def page_title title
    hr
    h 1 do
      text title
    end
    hr
  end



  def table(css_class = nil, &block)
    attr = class_attr css_class
    element_block 'table', attr, &block
  end
  def tr(css_class = nil,&block)
    attr = class_attr css_class
    element_block 'tr', attr, &block
  end
  def td(css_class = nil,&block)
    attr = class_attr css_class
    element_span 'td', attr, &block
  end
  def th(css_class = nil,&block)
    attr = class_attr css_class
    element_span 'th', attr, &block
  end

  def col (width_percent = nil, &block)
    attrs = {'valign' => 'top'}
    attrs['width'] = width_percent.to_s + '%' if width_percent
    element_span "TD", attrs, &block
  end

  def error aString
    text "*** #{aString} ***"
    $stderr.puts "WARNING: " + aString
  end
  def lf
      text "<BR/>"
  end

  def ul(&block)
    element_block 'ul', nil, &block
  end
  def li(&block)
    element_block 'li', nil, &block
  end

  def include fileName
    File.foreach(fileName) {|line| self << line}
  end
	def div css_class = nil, attrs = {}, &block
    attrs['class'] = css_class if css_class
		element_block "div", attrs, &block		
	end
  def div_id id, &block
    attr = {:id => id}
    element_block "div", attr, &block
  end
  def class_attr value
    return (value)  ? {'class' => value} : nil
  end
  def doctype
    text '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
  end
  def css uri
    attrs = {:href => uri, :rel => 'stylesheet', :type => 'text/css'}
    element_block('link', attrs){}
  end
  def markdown src
    require 'kramdown'
    @out << Kramdown::Document.new(src).to_html
  end
end

class LinkFixingEmitter < DelegateClass(HtmlEmitter)
  def initialize target
    super(target)
    @prepend = ""
  end
  def prepend= arg
    @prepend = arg
  end
  def with_prepend arg
    @prepend = arg
    return self
  end
  def fix uri
    uri.start_with?('http://') ? uri : @prepend + uri
  end
  def a_ref(href, &block)
    __getobj__.a_ref(fix(href), &block)
  end
  def element_span(name, attributes = nil, &block)
    fix_in_element name, attributes
     __getobj__.element_span(name, attributes, &block)
  end
  def element(name, attributes = nil, &block)
    fix_in_element name, attributes
     __getobj__.element(name, attributes, &block)
  end
  def fix_in_element name, attributes
    if "a" == name
      attributes['href'] = fix(attributes['href']) if attributes.key? 'href'
      attributes[:href]  = fix(attributes[:href])  if attributes.key? :href
    end
  end
end
end
