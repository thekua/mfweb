# tasks and functions widely used by rest of build system
include Rake::DSL

def ensure_rm file
  rm_r file if File.exists? file
end
QUIET = {:verbose => false}


#==== logging ================

require 'logger'
$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO
$logger.formatter = proc do |sev, time, progname, msg|
  ('INFO' == sev) ? 
    "#{msg}\n" : 
    "[#{sev}] #{msg}\n"
end

def log message = nil
  if message
    $logger.info message
  else
    $logger
  end
end

#----------------------------------------------------------------

def sassTask srcGlob, relativeTargetDir, taskSymbol, deps = []
  FileList[srcGlob].each do |src|
    targetDir = BUILD_DIR + relativeTargetDir
    target = File.join(targetDir, src.pathmap("%n.css"))
    srcDir = src.pathmap "%d"
    task taskSymbol => target
    file target => [src] + deps do 
      puts "sass #{src}"
      mkdir_p targetDir, QUIET
      require "sass"
      sass = Sass::Engine.new(File.read(src), 
                              :syntax => :scss, :load_paths => [srcDir] + CSS_PATHS)
      File.open(target, 'w') {|out| out << sass.render}
     end
  end
end

def xslTask src, relativeTargetDir, taskSymbol, style, css = 'global.css'
  targetDir = BUILD_DIR + relativeTargetDir
  target = File.join(targetDir, File.basename(src, '.xml') + '.html')
  task taskSymbol => target
  file target => [src, style, :base] do |t|
    puts "xsl: " + src
    mkdir_p targetDir, QUIET
    bare_html = `xsltproc #{style} #{src}`
    raise "XSLT failed" if bare_html.empty?
    File.open(target, 'w') do |out|
      mesher_with_content(css).run(bare_html, out)
    end
  end
end   

def copyTask srcGlob, targetDirSuffix, taskSymbol 
  targetDir = BUILD_DIR + targetDirSuffix
  FileList[srcGlob].each do |f|
    target = File.join targetDir, File.basename(f)
    file target => [f] do |t|
      mkdir_p targetDir, QUIET
      install f, target, QUIET
    end
    task taskSymbol => target
  end
end

def copyGraphicsTask srcDir, targetDirSuffix, taskSymbol
  %w[gif jpg png].each do |i|
    copyTask srcDir + "/*." + i, targetDirSuffix, taskSymbol
  end
end

def markdown_task src, relativeTargetDir, taskSymbol, title
  targetDir = BUILD_DIR + relativeTargetDir
  target = File.join(targetDir, src.pathmap('%n.html'))
  task taskSymbol => target
  file target => [src, :base] do |t|
    skeleton = Site.skeleton.with_css('/global.css')
    build_markdown src, target, skeleton, title
  end
end


def build_markdown src, target, skeleton, title
  puts "kramdown #{src} -> #{target}"
  require 'kramdown'
  skeleton.emit_file(target, title) do |html|
    html << Kramdown::Document.new(File.read(src)).to_html
  end
end

def build_simple_articles skeleton = nil
  FileList['articles/simple/*.xml'].each do |src|
    target = src.pathmap(BUILD_DIR + 'articles/%n.html')
    file target => [src] do |t|
      maker = Mfweb::Article::ArticleMaker.new t.prerequisites[0], t.name, skeleton
      maker.bib_server = Mfweb::Article::Bibliography.new 'bib.xml', src
      maker.code_server = Mfweb::Article::CodeServer.new 'articles/simple/code/'   
      maker.footnote_server = Mfweb::Article::FootnoteServer.new src
      begin
        maker.run
      rescue 
        rm target
        raise $!
      end
    end
    task :articles => target
  end
  copyGraphicsTask 'articles/simple/images', 'articles', :articles
  FileList['articles/simple/images/*'].each do |dir|
    target_dir = "articles/images/" + dir.pathmap("%n")
    copyGraphicsTask dir, target_dir, :articles
  end
end
