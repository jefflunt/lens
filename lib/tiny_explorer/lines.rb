require 'tiny_dot'

module TinyExplorer
  # this class contains a collection of log lines
  class LineReader
    attr_reader :config

    # raw lines
    # -> window, controls how many total lines to display
    #   | -> filter
    #   | -> mapper
    #   | -> highlighter
    # -

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
    # new_line_listener: an object to be notified when a new line shows up
    #   defaults to nil, which means no one will be notified of new lines
    #   the object passed in must respond to a #new_line method
    #   this option is ignored if `tail' is false
    def initialize(io: $stdin, tail: true, new_line_listener: nil)
      raise TinyExplorer::InvalidNewLineListenerError.new('The new line listener passed in does not respond to #new_line') unless new_line_listener.respond_to?(:new_line)

      @io = io
      @tail = tail
      @log_lines = []

      if tail
        Thread.new do
          loop do
            new_line = @io.gets.strip
            @log_lines << new_line
            new_line_listener&.new_line(new_line)
          end
        end
      else
        @log_lines = @io.read.lines.map(&:strip)
      end
    end

    def [](index)
      @log_lines[index]
    end
  end
end

class TinyExplorer::InvalidNewLineListenerError < RuntimeError; end
