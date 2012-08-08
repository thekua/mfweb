module Mfweb::Article

class ArticleMaker < Mfweb::Core::TransformerPageRenderer
  attr_accessor :pattern_server, 
    :code_server, :bib_server, :footnote_server, :catalog
  def initialize infile, outfile, skeleton = nil, transformerClass = nil
    @catalog = Mfweb::Core::Site.catalog
    super(infile, outfile, transformerClass, skeleton)
    @skeleton ||=  Mfweb::Core::Site.
      skeleton.with_css('article.css').
      with_banner_for_tags(tags)
    puts "#{@in_file} -> #{@out_file}" #TODO move to rake task
    @pattern_server = PatternServer.new
    @code_server = CodeServer.new
    @bib_server = Bibliography.new
    @footnote_server = FootnoteServer.new
    @code_dir = './'
  end

  def render_body
    if 'dev' == @root['status']
      render_draft_notice
    end
    @transformer.render
    @transformer.render_revision_history
  end

  def create_transformer
    if @transformer_class 
      return super
    else
      return case @root.name
             when 'paper'   then PaperTransformer.new(@html, @root, self)
             when 'pattern' then PatternHandler.new(@html, @root, self)
             else raise "no transformer for #{@in_file}"
             end
    end
  end

  def render_draft_notice
    @html.div("draft-notice") do
      @html.h(1) {@html.text "Draft"}
      @html.p {@html.text "This article is a draft.<br/>Please do not share or link to this URL until I remove this notice"}
    end
  end

  def key
    return File.basename(@out_file, '.html')
  end

  def tags
    # some old papers are not registered in catalog
    if @catalog && @catalog[key]
      return @catalog[key].tags
    else
      return []
    end
  end
end


end
