module Mfweb::Article

class CodeServer

  def find file, fragment
    return fragment ? 
      find_fragment(file, fragment) :
      whole_file(file)
  end

  def whole_file file
    unless @whole_files[file]
      codeFile = File.join(@code_dir, file)
      @whole_files[file] = File.readlines(codeFile).join
    end
    return CodeFragment.new(@whole_files[file])
  end

  def find_fragment file, fragment
    unless @files[file]
      codeFile = File.join(@code_dir, file)
      frag = Fragmentor.new(codeFile)
      frag.run
      @files[file] = frag
    end
    return @files[file][fragment]   
  end
  def initialize code_dir = './'
    @code_dir = code_dir
    @files = {}
    @whole_files = {}
  end
  def path
    return @code_dir
  end

  def render_insertCode anElement, html
    #renders the usual insertCode element onto an html renderer
    attributes = nil
    if anElement['cssClass']
      attributes = { 'class' => anElement['cssClass'] }
    end
    html.element('pre', attributes) do
      begin
        use_class_name = 'true' == anElement['useClassName']
        unless use_class_name
          if anElement['class'] #TODO remove class element from old docs
            html.text "class #{anElement['class']}...\n"
          elsif anElement['label']
            html.text "#{anElement['label']}...\n"
          end
        end
        frag = find anElement['file'], anElement['fragment']
        html.text "#{frag.class}...\n" if use_class_name
        html.cdata(frag.result.gsub("\t", "  "))
      rescue MissingFragmentFile
        html.error "missing file: #{anElement['file']} in #{path}"
      rescue MissingFragment
        html.error "missing fragment: #{anElement['fragment']}"
      end
    end
  end

end


class Fragmentor
# Pulls source code fragments out of source files. Any text file
# can be chopped. Surround between <codeFragment name = 'THE_NAME'>
# and </codeFragment

  attr_reader :class
  def initialize file
    @file = file
    @class = nil
    @frags = {}
  end

  def run
    raise MissingFragmentFile, @file unless FileTest.exists? @file
    fragsByName = Hash.new
    fragNames = []
    File.new(@file).each_line do |line|
      match_class_name line
      if line =~ %r{</codeFragment>}
        @frags[fragNames.last] = CodeFragment.new(fragsByName[fragNames.last], @class)
        fragNames.pop
      end

      fragNames.each do |name|
        fragsByName[name] << line if line !~/<\/{0,1}codeFragment.*>/
      end

      if line =~ /<codeFragment/
        line =~ /name\s*=\s*"(\w*)"/
        fragNames << $1
        fragsByName[$1] = ""
      end
    end
  end

  def [] frag
    if @frags[frag]     
      return @frags[frag]
    else
      raise(MissingFragment, frag)
    end
  end
  
  def match_class_name line
    return if @class #only want the first match
    line =~ /(class\s+(\w*))/
    @class = $~[1] if $~
  end



end

class CodeFragment
  attr_reader :result, :class
  def initialize code, klass = ""
    @result, @class = code, klass
  end
end


class FragmentError < StandardError
end
class MissingFragmentFile < FragmentError 
end
class MissingFragment < FragmentError
end

end
