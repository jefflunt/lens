module TinyExplorer
  # this class implements a data pipeline through which log lines are passed,
  # resulting in output lines for display
  class Pipeline
    # io: the IO object from which to read log lines
    # steps: the list of procs to be run over the IO log lines, in the order in
    #   which they should be run
    def initialize(io, steps)
      @steps = steps
      @selected = []

      Thread.new do
        loop do
          new_line = io.gets&.strip
          break if new_line.nil?

          @selected << new_line
        end
      end
    end

    def [](window)
      @selected[window]
    end

    def new_line(l)
      return unless l

      new_l = l

      steps.each do |s|
        new_l = s.call(new_l)
        return if new_l.nil?
      end

      @selected << new_l
    end
  end
end
