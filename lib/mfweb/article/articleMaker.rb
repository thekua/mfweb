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

  def load
    super
    @skeleton = @skeleton.as_draft if 'dev' == @root['status']
  end

  def render_body
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
