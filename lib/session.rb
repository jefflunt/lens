# a session contains cross-buffer things, such as the clipboard (i.e. clips)
class Session
  attr_reader :clips,
              :buffers

  def initialize(starting_path=nil)
    @buffers = []
    @buffers << Buffer.new(Rouge::Formatters::Terminal256.new, starting_path) if starting_path
    @buffers << Buffer.new(Rouge::Formatters::Terminal256.new)            unless starting_path

    @clips = {}
  end

  def clip(key)
    @clips[key]
  end

  def clip=(key, value)
    @clips[key] = value
  end
end
