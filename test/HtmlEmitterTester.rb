require 'test/unit'
require 'stringio'
require 'rubygems'
require 'mfweb/core'

class LinkFixingEmitterTester < Test::Unit::TestCase
  include Mfweb::Core
  def setup
    @raw_emitter = HtmlEmitter.new
  end
  def run_emitter
    @emitter.p do
      @emitter.a_ref("ref"){@emitter << "content"}
    end
    @html = Nokogiri::HTML(@emitter.out)
    @a_ref = @html.at_css('a')['href']
  end
  def test_by_default_makes_no_change
    @emitter = LinkFixingEmitter.new(@raw_emitter)
    run_emitter
    assert_equal 'ref', @a_ref
  end
  def test_can_add_in_parent_dir
    @emitter = LinkFixingEmitter.new(@raw_emitter)
    @emitter.prepend = "../"
    run_emitter
    assert_equal '../ref', @a_ref
  end
  def test_fixed_when_using_element
    @emitter = LinkFixingEmitter.new(@raw_emitter)
    @emitter.prepend = "../"
    @emitter.element("a", {:href => 'ref'}){@emitter << "content"}
    @html = Nokogiri::HTML(@emitter.out)
    assert_equal '../ref', @html.at_css('a')['href']
  end
  def test_fixed_when_using_element_span
    @emitter = LinkFixingEmitter.new(@raw_emitter)
    @emitter.prepend = "../"
    @emitter.element_span("a", {:href => 'ref'}){@emitter << "content"}
    @html = Nokogiri::HTML(@emitter.out)
    assert_equal '../ref', @html.at_css('a')['href']
  end

end
