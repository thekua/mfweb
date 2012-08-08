require 'test/unit'
require 'mfweb/article'

class BibliographyTester < Test::Unit::TestCase
  include Mfweb::Core
  include Mfweb::Article
  def test_read_bib_ref_from_single_file
    bib = Bibliography.new('test/bib.xml')
    assert_equal 'http://c2.com/ppr/checks.html', bib['cunningham-checks'].url
  end
  def test_read_bib_refs_from_article_file
    bib = Bibliography.new('sample/articles/simple/simpleArticle.xml')
    assert_equal 'http://www.amazon.com/exec/obidos/ASIN/0201616416', bib['beckXPE'].url
  end
  def test_read_two_bibliographies
    bib = Bibliography.new('test/bib.xml', 'sample/articles/simple/simpleArticle.xml')
    assert_equal 'http://c2.com/ppr/checks.html', bib['cunningham-checks'].url
    assert_equal 'http://www.amazon.com/exec/obidos/ASIN/0201616416', bib['beckXPE'].url    
  end
end
