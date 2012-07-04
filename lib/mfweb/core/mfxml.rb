module MfXml 
  def self.root aStream
    doc = Nokogiri::XML(aStream)
    unless doc.errors.empty?
      raise "processing errors: \n" +  doc.errors.join("\n")
    end
    return doc.root
  end
end

module Nokogiri::XML
  class Node
    def has_text?
      texts = children.select{|c| c.text?}
      return false if texts.empty?
      return texts.any?{|t| not t.content.empty?}
    end    
    def has_attributes? 
      not keys.empty?
    end
    def entity_ref?
      Nokogiri::XML::Node::ENTITY_REF_NODE == type
    end
  end

end
