module TinyExplorer
  # this class implements a data pipeline through which log lines are passed,
  # resulting in output lines for display
  class Pipeline
    attr_reader :read

    # io: the IO object from which to read log lines
    # procs: the list of procs to be run over the IO log lines, in the order in
    #   which they should be run
    def initialize(io, procs)
      @procs = procs
      @selected = []
      @read = 0

      puts "IO class: #{io.class}"
      case io
      when String
        puts "Reading as String"
        IO.read(io).lines.map(&:strip).each{|line| _process(line) }
      when IO
        puts "Reading as IO"
        puts io.inspect
        Thread.new do
          loop do
            line = io.gets&.strip
            break if io.eof?

            _process(line)
          end
        end
      end
    end

    # tells you the number of lines currently stored in this Pipeline
    def length
      @selected.length
    end

    # gives Array-like indexing over the lines in this Pipeline
    def [](window)
      @selected[window]
    end

    def _process(line)
      @procs.each do |p|
        break if line.nil?
        line = p.call(line)
      end

      @read += 1
      @selected << line if line
    end
  end
end
