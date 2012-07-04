module Mfweb::Core::XpathFunctions

    def xpath expr, anElement = @root
      anElement.xpath expr
    end

    def xpath_only expr, anElement = @root
      #TODO replace with at_xpath
      nodes = xpath(expr, anElement)
      raise 'more than one result' if 1 < nodes.size
      return nodes[0]
    end
    
    def xpath_first expr, anElement = @root
      return xpath(expr, anElement)[0]
    end
end
