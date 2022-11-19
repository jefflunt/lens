require 'tiny_dot'

class TinyExplorer
  attr_reader :config

  # io: the I/O object to read log lines from
  #   if not specified, then defaults to $stdin
  #   if specified, then uses that I/O object to read log lines. an example use would be to pass a File object to this, or an
  # config: the config you want to use
  #   if specified, it should be an instance of TinyDot
  #   if not specified, defaults to wrapping .tiny_explorer.config.yml with an
  #     instance of TinyDot
  # tail: boolean, true by default
  #   if true, then TinyExplorer will attempt to live-tail the IO object
  #   if false, then a single read on the I/O object will happen during initialization, and new log lines added after in
  def initialize(io: $stdin, config: TinyDot.from_yaml_file('.tiny_explorer.config.yml'), tail: true)
    @io = io
    @config = config
    @tail = tail
    @log_lines = []

    if tail
      Thread.new do
        loop do
          @log_lines << @io.gets.strip
        end
      end
    else
      @log_lines = @io.read.lines.map(&:strip)
    end
  end

  def reconfigure(config)
    @config = config
  end
end
