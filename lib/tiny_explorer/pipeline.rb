module TinyExplorer
  # this class implements a data pipeline through which log lines are passed,
  # resulting in output lines for display
  class Pipeline
    # line_reader: an instance of LineReader, which contains the lines that
    #   should be passed through this Pipeline
    # steps: the list of steps to be run over the log lines from line_reader
    #   if you want no processing, pass in an empty list `[]'
    def initialize(steps)
      @steps = steps
      @selected = []
    end

    def [](window)
      @selected[window]
    end

    def new_line(l)
      new_l = l

      steps.each do |s|
        new_l = s.call(new_l)
        return if new_l.nil?
      end

      @selected << new_l
    end
  end
end
