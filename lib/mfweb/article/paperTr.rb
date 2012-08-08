module Mfweb::Article

class PaperTransformer < Mfweb::Core::Transformer
  include Mfweb::Core::HtmlUtils
  include Mfweb::Core::XpathFunctions
  def initialize output, root, maker
    raise 'heck' unless output
    super output, root
    @maker = maker
    @copy_set = %w[b i p ul li a code img table tr th td div ol]
    @ignore_set = %w[footnote-list]
    @section_depth = 1
    @has_printed_version = false
  end

  def title_bar_text
    return xpath_only('//title').text
  end

  def render_revision_history
    @html.div('appendix') do
      @html.h(2) do 
        @html.a_name 'SignificantRevisions'
        @html.text "Significant Revisions"
      end
      xpath("version").each do |v|
        @html.p do
          date = v['date']
          @html.i {@html.text "#{print_date date}: "}
          apply v
        end
      end
    end
  end

  def print_date aDateString
   return (/^\D+\s+\d+$/ =~ aDateString) ? 
    aDateString : # if like "July 2001"
      Date.parse(aDateString).strftime("%d %B %Y")
  end

  def footnote_server
    unless @footnote_server
      if @maker.respond_to? :footnote_server
        @footnote_server = @maker.footnote_server
      else 
        @footnote_server = FootnoteServer.new
        @footnote_server.load_doc(@root)
      end
    end
    @footnote_server
  end

  def handle_title anElement
    @html.h(1) {apply anElement}
  end
  def handle_subtitle anElement
    @html.p("subtitle") {apply anElement}
  end
  def handle_paper anElement
    @figureReader = FigureReader.new anElement
    @is_draft = ('dev' == anElement["status"])
    apply anElement
  end
  def draft?
    @is_draft
  end
  def handle_credits anElementl; end
  def handle_version anElement
    # ignore - printed during handling of abstract
  end
  def handle_translation anElement
    #ignore - printed during handling of abstract
  end
  def handle_contents anElement; end
  def default_handler anElement
    raise "unhandled case: " + anElement.name
    puts 'unhandled: ' + anElement.name
  end
  def handle_abstract anElement
    print_topImage
    @html.p('abstract'){@html.i{apply anElement}}
    print_front_matter
  end
  def print_front_matter
    FrontMatterTransformer.new(@html, @root, @maker).handle(@root)
  end
  def handle_topImage anElement; end
  def print_topImage
    elem = xpath_only('//paper/topImage')
    return unless elem
    attrs = {}
    case elem['layout']
      when 'full' then attrs['class'] = 'fullPhoto'
      when nil then attrs['id'] = 'topImage'
    end
    width = elem['width']
    attrs['style'] = "width: #{width}px;" if width
    @html.element('div', attrs) do
      @html.element('img', {:src => elem['src']}){}
      render_photo_credit elem
      if elem.has_text?
        @html.p {apply elem}
      end
    end
  end
  def handle_section anElement
    @section_depth += 1
    @html.hr('topSection') if @section_depth == 2
    apply anElement
    @section_depth -= 1
  end
  def handle_H anElement
    attrs = {:id => anchor_for(anElement.parent)}
    @html.h(@section_depth, attrs) {apply anElement}
  end
  alias :handle_h :handle_H
  def handle_topBox anElement;  end


  def handle_body anElement
    attrs = {'class' => 'bodySep'}
    @html.div('paperBody') do
      apply anElement
      @html.element('hr', attrs){}
    end
  end
  def handle_appendix anElement
    @html.div('appendix') {apply anElement}
  end
  def section_title aSectionElement
    flatten_content aSectionElement.at_xpath('H|h')
  end
  def flatten_content anElement
    buffer = StringIO.new
    fakeRenderer = Mfweb::Core::HtmlEmitter.new(buffer)
    trueRenderer = @html
    @html = fakeRenderer
    apply anElement
    @html = trueRenderer
    return strip_tags(buffer.string.strip)
   end
  def strip_tags aString
    #can't handle loose > in content
    aString.gsub(/<\/?[^>]*>/, "")
  end
  def anchor_for aSectionElement
    return aSectionElement['ID'] || 
      section_title(aSectionElement).to_anchor
  end
  def handle_cite anElement   
    bibref = @maker.bib_server[anElement['name']]
    if anElement.has_text?
      cite_around anElement, bibref
    else
      if bibref.url
        @html.a_ref(bibref.url){@html.text bibref.cite}
      else
        @html.text bibref.cite
      end
    end
  end
  def cite_around anElement, bibref
    if bibref.url
      @html.a_ref(bibref.url){apply anElement}
    else
      apply anElement
      @html.text "[#{bibref.name}]"
    end
  end
  def handle_patternRef anElement
    key = anElement['name']
    pattern = @maker.pattern_server.find key
    name = pattern.name
    name += "s" if "plural" == anElement['mode']
    if pattern.missing?
      @html.error pattern.message
    else
      @html.a_ref(pattern.url){@html.text name}
    end     
  end
  def handle_blikiRef anElement
    name = anElement['name']
    href = "http://martinfowler.com/bliki/#{name}.html"
    text = name.gsub(/[A-Z]/, ' \&')
    text += 's' if 'plural' == anElement['mode'] 
    @html.a_ref(href){@html.text text}
  end
  def handle_photo anElement
    width = anElement['width']
    css_class = case anElement['layout'] 
                  when "full" then "fullPhoto"
                  when "right" then "photo"
                  when nil then "photo"
                  else raise "unknown photo layout: " + anElement
                end
    @html.element('div', {:class => css_class, 
                    :style => "width: #{width}px;" }) do
      attrs = {:src => anElement['src']}
      @html.element('img', attrs){}
      render_photo_credit anElement
      @html.p('photoCaption') {apply anElement}
    end
  end
  def render_photo_credit anElement
    if anElement['credit']
      @html.p('credit') do
        @html << "photo: " + anElement['credit']
      end
    end
  end
  def handle_sidebar anElement
    @html.div('sidebar') {apply anElement}
  end
  def handle_soundbite anElement
    @html.div('soundbyte') do
      @html.p {apply anElement}
    end
  end
  def handle_figure anElement
    @html.div('figure') do
      if anElement['align']
        puts "can't handle alignment attribute in figure yet"
      end
      src = anElement['src']
      fig_num = @figureReader.number(src)
      @html.p('figureImage')do
        @html.element('a', 'name' => a_name(src)) {}
        img_attrs = {}
        img_attrs['src'] = src
        img_attrs['alt'] = "Figure #{fig_num}"
        # img_attrs['align'] = 'top'
        @html.element('img', img_attrs) {}
      end
      @html.p('figureCaption') do 
        @html.text "Figure #{fig_num}: "
        apply anElement
      end
    end
  end
  def a_name aString
    return aString.gsub("/", "_")
  end
  def handle_book anElement
    emit_amazon anElement, anElement['isbn']
  end
  def handle_tbd anElement
    if draft?
      emitTbd anElement
    else
      log.warn "TBD: #{anElement.text}"
    end
  end
  def emitTbd anElement
    if %w[section body].include? anElement.parent.name
      @html.p {emitTbdSpan anElement}
    else
      emitTbdSpan anElement
    end
  end
  def emitTbdSpan anElement
    @html.span('tbd') do
      @html.text "[TBD: #{anElement.text}]"
    end
  end
  def handle_term anElement
    @html.b{apply anElement}
  end
  def handle_figureRef anElement
    apply anElement
    ref = anElement['ref']
    ref_text = ' Figure ' + @figureReader.number(ref)
    @html.a_ref('#' + a_name(ref)) {@html.text ref_text}
  end 
  def handle_pre anElement
    @html.element('pre') {apply anElement}
  end

  def handle_insertCode anElement
    @maker.code_server.render_insertCode anElement, @html
  end

  def handle_author anElement
    #skip
  end 

  def handle_xref anElement
    href = ""
    file = anElement['file']
    href = file.sub('.xml', '.html') if file
    id = anElement['targetID']
    href << "#" + id if id
      
    @html.a_ref(href) {apply anElement}
  end
  def handle_xref_target anElement
    @html.a_name anElement['ID']
  end
  def handle_quote anElement
    @html.element('blockquote') do
      apply anElement
      @html.p('quote-attribution') {render_cite anElement}
    end
  end
  def render_cite anElement
    ref = anElement['ref']
    bibref = @maker.bib_server[ref] if ref
    credit = anElement['credit'] || anElement['source']
    # HACKTAG use of source attr comes from bliki
    uri = anElement['url'] || (bibref && bibref.url)
    return unless ref || credit
    @html.text "-- "
    cite_text = credit || bibref.cite
    if uri
      @html.a_ref(uri){@html.text cite_text}
    else
      @html.text cite_text
    end
  end

  def handle_amazon anElement
    emit_amazon anElement, anElement['key']
  end    

  def handle_br anElement
    #needs special handling as <br></br> renders differently
    @html << "<br/>"
  end

  def handle_footRef anElement
    key = anElement['key']
    
    footnote_server.record key
    @html << footnote_server.render_reference(key)
  end

  def handle_display_footnotes anElement
    @html.div('footnote-list') do
      @html.h(2){@html << "Footnotes"}
      footnote_server.references.each do |key|
        render_footnote key
      end
    end
  end

  def render_footnote key 
    @html.element('div', 
                 :class => 'footnote-list-item', 
                 :id => footnote_server.anchor(key)) do
      head =  footnote_server.head(key)
      if head
        render_footnote_head key
        render_footnote_body key
      else 
        render_footnote_text key
      end
    end
  end

  def render_footnote_head key
    @html.element('h3', :class => 'head-text') do
      @html << "#{footnote_server.marker(key)}: "
      head =  footnote_server.head(key)
      @html << head.text 
    end
  end

  def render_footnote_body key
    footnote_server.body(key).each {|e| handle e}
  end
  
  def render_footnote_text key
    @html.p do
      @html.span('num') {@html << "#{footnote_server.marker(key)}: "}
      render_footnote_body key
      #@html << footnote_server.body(key)
    end
  end
  
end

#==== Full Author Transformer ================================

class FullAuthorTransformer < Mfweb::Core::Transformer
  include Mfweb::Core::XpathFunctions

  def initialize htmlRenderer, rootElement
    super htmlRenderer, rootElement
    @apply_set = %w[author-bio]
    @copy_set = %w[p a i b]
  end
  def default_handler anElement
    $stderr.puts "Can't handle: #{anElement.name}"
  end

  def handle_author anElement
    @html.div('author') do 
      photo = xpath_only('author-photo', anElement)
      if photo
        attrs = {}
        attrs['src'] = photo['src']
        name = xpath_only('author-name', anElement).text
        attrs['alt'] = "Photo of #{name}"
        attrs[:width] = '80'
        @html.element('img', attrs) {}
      end
      print_name anElement
      apply anElement
    end
    @html.div('clear'){}
  end

  def  print_name authorElement
    name = xpath_only('author-name', authorElement)
    url = xpath_only('author-url', authorElement)
    @html.p('name') do
      if url
        @html.a_ref(url.text) {@html.text name.text }
      else
        @html.text name.text
      end
    end
  end

  def handle_author_name anElement ; end
  def handle_author_url anElement; end
  def handle_author_photo anElement; end
end

#==== Front Matter Transformer  ================================

class FrontMatterTransformer < PaperTransformer
  def initialize *args
    super(*args)
  end
  def handle_paper anElement
    assert_valid
    @html.div('frontMatter') do
      @html.div('frontLeft') do
        print_version
        print_authors
        print_translations anElement
        print_tags
        print_topBox
      end
      @html.div('frontRight') do
        print_contents
      end
    end
  end
  
  def assert_valid
    credits = xpath("//credits")
    unless credits.empty?
      authors = xpath("//author")
      raise "credits but no authors" if authors.empty?
    end
  end


  def print_version 
    latest_version = xpath_first('version')
    date = latest_version['date']
    @html.p('date') {@html.text print_date(date)}
  end

  def print_authors 
    elements = xpath('/*/author').each {|e| handle e}
  end

  def handle_author anElement
    handler = FullAuthorTransformer.new(@html, anElement)
    handler.render
  end

  def print_translations anElement
    trans = xpath('//paper/translation')
    return if trans.empty?
    @html.div('translations') do
      @html.b {@html.text "Translations: "}
      trans.each do |t|
        @html.a_ref(t['url']) do
          @html.text t['language']
        end
        @html.text " "
      end
    end
  end
  
  def print_tags
    @html.div('tags') do
      @html.b {@html << "Tags: "  }
      @html << @maker.tags.collect{|t| t.link}.join(dot_sep)
    end
  end

  def print_topBox 
    topBox = xpath('//paper/topBox').first
    handle topBox if topBox
  end


  def handle_topBox anElement
    @html.div('topBox') do
      apply anElement
    end
  end


  def print_contents 
    @html.div('contents') do
      @html.h(2) {@html.text 'Contents'}
      @html.ul  do
        xpath('body/section').each {|s| print_contents_for s}
      end
    end
  end

  def print_contents_for aSection
    @html.li do
      @html.a_ref("##{anchor_for(aSection)}") do
        @html.text(section_title(aSection))
      end
      subSections = xpath('section', aSection)
      unless subSections.empty?
        @html.ul {subSections.each {|s| print_contents_for s} }
      end
    end
  end

  def handle_abstract anElement;  end #skip
  def handle_body anElement;  end #skip
  def handle_title anElement; end #skip
  def default_handler anElement; end
end

class FigureReader
  include Mfweb::Core::XpathFunctions
  def initialize rootElement
    @root = rootElement
    @figures = load_figures @root
  end
  def load_figures anElement
    figure_elements = xpath('//figure', anElement)
    return figure_elements.collect {|e| e['src']}
  end 
  def number srcString
    index = (@figures.index(srcString))
    if index
      return (index + 1).to_s
    else
      puts "no figure for #{srcString}"
      return "?"
    end
  end
end

end
