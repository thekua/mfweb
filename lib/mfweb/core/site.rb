module Mfweb::Core
class Site
  def self.master
    raise "site not initialized" unless initialized?
    @@master
  end
  def self.init master
    unless initialized?
      @@master = master
    end
  end
  def self.initialized?
    defined? @@master && @master
  end
  def self.method_missing name, *args
    master.send name, *args
  end
  def catalog
    load_catalog
    return @catalog
  end
  def skeleton
    load_skeleton
    return @skeleton
  end

  # hook methods
  def load_skeleton; end
  def load_catalog; end
end
end
