class String
  def to_anchor
    words = self.split
    words.each {|w| w.capitalize!}
    result = words.join
    nmtokens = /[\w.-]*/
    result2 = result.scan(nmtokens).join
    return result2
  end
end

def parse_date aString
  Date.parse(aString)
end

class Array
  def even_elements
    result = []
    each_with_index{|e, i| result << e if i.even?}
    return result
  end
  def odd_elements
    result = []
    each_with_index{|e, i| result << e unless i.even?}
    return result
  end
end


