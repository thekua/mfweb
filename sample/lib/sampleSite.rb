class SampleSite < Mfweb::Core::Site
  def load_skeleton
    @header = "<div id = 'banner'></div>"
    @footer = "<div id = 'footer'></div>"
    @skeleton = Mfweb::Core::PageSkeleton.new(@header, @footer, 'global.css')    
  end
end


