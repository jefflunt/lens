# a text buffer with marks, selections, and rudimentary editing
class Buffer
  attr_reader :chars,
              :bytes,
              :lines,
              :length,
              :line_no_width,
              :max_char_width,
              :rect,
              :caret,
              :history,
              :marks,
              :selections

  # gives you a default, empty, zero slice
  #
  # formatter - a Rouge formatter
  # lexer - a Rouge lexer
  def initialize(formatter, lexer, filename='')
    @pathname = !filename.nil? && !filename.empty? ? Pathname.new(filename).realpath : nil

    @formatter = formatter
    @lexer = lexer
    @rect = [0, 0, 0, 0]    # the default slice is at the beginning of the buffer, and has a zero size
    @caret = [c, r]

    # size tracking
    @chars = 0        # the number of characters in the buffer (not the same as the number of bytes)
    @bytes = 0        # the number of bytes in the buffer (not the same as the number of characters)
    @lines = ['']
    @line_no_width = 1
    @rendered_lines = [] # fully formatted, syntax highlighted, and transformed
    @max_char_width = 0
    @all_buff = @lines.join("\n")

    @history = []
    @marks = {}
    @selections = {}

    @lines = IO.readlines(filename).map(&:chomp) if @pathname
    @max_char_width = @lines.map(&:length).max
    @bytes = @lines.map(&:bytesize).sum
    @chars = @lines.map(&:length).sum

    modified!
  end

  def method_missing(method, *args, **kwargs, &block)
    print "\a"
  end

  def save
    return unless @pathname

    Thread.new do
      File.open(@pathname, 'w') {|f| f.write(@lines.join("\n")) }
    end

    nil
  end

  def line_at(i)
    @lines[i]
  end

  def delete_current_line
    @lines.delete_at(caret[1])
    @lines = [""] if @lines.length == 0
    @caret[1] -= 1 if @lines.length == caret[1]
    modified!
  end

  def char_at(x, y)
    (l = line_at(y)) && l[x]
  end

  def modified!
    @modified = true
  end

  def unmodified!
    @modified = false
  end

  # move the buffer's visible coordinates, and possibly the caret as well, if
  # moving the window would cause the caret to be out-of-bounds
  def rect=(coords)
    @rect = coords

    adjust_caret!
  end

  # index of first visible column
  def c
    @rect[0]
  end

  # index of first visible row
  def r
    @rect[1]
  end

  # width of the buffer window
  def w
    @rect[2]
  end

  # height of the buffer window
  def h
    @rect[3]
  end

  # used when the rect is panned/scolled, keeps the screen caret within the rect
  # see: adjust_rect!
  def adjust_caret!
    cx, cy = @caret
    new_cx = if cx < c
               c
             elsif cx > c + w
               w
             else
               cx
             end

    new_cy = if cy < r
               r
             elsif cy > (r + h - 1)
               r + h - 1
             else
               cy
             end

    @caret = [new_cx, new_cy]
  end

  # used when the caret is moved, moves the rect to keep the caret on screen
  # see: adjust_caret!
  def adjust_rect!
    scx, scy = screen_caret
    rx, ry = @rect[0], @rect[1]

    new_rx = if scx > (w - 1)
               rx + (scx - (w - 1))
             elsif scx <= line_no_width
               rx - (line_no_width - scx) - 1
             else
               rx
             end

    new_ry = if scy > (h - 1)
               ry + (scy - (h - 1))
             elsif scy < 0
               ry + scy
             else
               ry
             end

    @rect[0] = new_rx #rx
    @rect[1] = new_ry #ry
  end

  def caret_down!(n=1)
    @caret[1] = [caret[1] + n, @lines.length - 1].min
    @caret[0] = [caret[0], @lines[caret[1]].length].min
    adjust_rect!
  end

  def caret_down_fast!
    caret_down!(5)
  end

  def caret_up!(n=1)
    @caret[1] = [caret[1] - n, 0].max
    @caret[0] = [caret[0], @lines[caret[1]].length].min
    adjust_rect!
  end

  def caret_up_fast!
    caret_up!(5)
  end

  def caret_left!(n=1)
    @caret[0] = [caret[0] - n, 0].max
    adjust_rect!
  end

  def caret_left_fast!
    caret_left!(5)
  end

  def caret_right!(n=1)
    @caret[0] = [caret[0] + n, @lines[caret[1]].length].min
    adjust_rect!
  end

  def caret_right_fast!
    caret_right!(5)
  end

  # you can think the caret position as the exact (x, y) position within a file
  # as a whole (like world coordinates within a video game), but the
  # screen_caret as the (x, y) position within the rendered portion of the
  # buffer (similar to screen coordinates within a buffer), but also offset by
  # the width of the line numbers.
  def screen_caret
    [
      caret[0] - c + line_no_width + 1, # '+ 1' is to account for a space between line numbers and caret
      caret[1] - r
    ]
  end

  # returns an array of strings representing the visible characters from this
  # Buffer's @rect - i.e. the rectangle that will be rendered onto the screen
  # when displayed to the user.
  def rect_s
    return [] if h == 0 || w == 0

    @line_no_width = @lines.length.to_s.length
    if @modified
      @rendered_lines = @formatter
        .format(
          @lexer.lex(
            @lines.join("\n")
          )
        )
        .lines
        .map(&:chomp)

      unmodified!
    else
      @rendered_lines[r..(r + visible_lines - 1)]
    end

    @rendered_lines[r..(r + visible_lines - 1)]
      .map.with_index{|row, i| "#{(i + r + 1).to_s.rjust(@line_no_width)} #{substr_with_color(row, c,  c + w - @line_no_width - 2)}" }
      .map{|l| "#{l}\e[0K" } +
      Array.new(blank_lines) { "\e[0K" }
  end

  # input - a String that may or may not contain ANSI color codes
  # start - the starting index of printable characters to keep
  # finish - the ending index of printable characters to keep
  #
  # treats `input' like a String that does
  def substr_with_color(input, start, finish)
    ansi_pattern = /\A\e\[[0-9;]+m/
    printable_counter = 0
    remaining = input.clone.chomp
    result = ''

    loop do
      break if remaining.empty? || printable_counter > finish

      match = remaining.match(ansi_pattern)
      if match
        result += match[0]
        remaining = remaining.sub(match[0], '')
      else
        result += remaining[0] if printable_counter >= start
        remaining = remaining[1..-1]
        printable_counter += 1
      end
    end

    result + "\e[0m"
  end

  # the number of visible lines from @lines at any given time
  def visible_lines
    [h, @lines.length - r].min
  end

  # the number of blank lines in the buffer after showing all visible lines.
  # this happens, for example, when you pan the buffer to the absolute last line
  # of the file - that last line now appears at the top of the rendered rect,
  # but below it nothing but blank lines, then the status line.
  def blank_lines
    [@rect[3] - visible_lines, 0].max
  end

  # scrolls the visible window up
  def rect_up!(n=1)
    @rect[1] = [@rect[1] - n, 0].max
    adjust_caret!
  end

  def rect_up_fast!
    rect_up!(5)
  end

  # scrolls the visible window down
  def rect_down!(n=1)
    @rect[1] = [@rect[1] + n, @lines.length - 1].min
    adjust_caret!
  end

  def rect_down_fast!
    rect_down!(5)
  end

  # scrolls the visible window left
  def rect_left!(n=1)
    @rect[0] = [@rect[0] - n, 0].max
    adjust_caret!
  end

  def rect_left_fast!
    rect_left!(5)
  end

  # scrolls the visible window right
  def rect_right!(n=1)
    @rect[0] = [@rect[0] + n, max_char_width - 1].min
    adjust_caret!
  end

  def rect_right_fast!
    rect_right!(5)
  end

  # set a mark, as in the Vim sense
  #
  # sym: the name of the mark
  # char_num: the number of characters from the top of the buffer to set the
  #   mark
  def mark(sym, char_num)
    @marks[sym] = [@chars, char_num].min

    nil
  end

  # remote a mark by name
  #
  # sym: the name of the mark to remove
  def unmark(sym)
    @marks.delete(sym)
    
    nil
  end

  # selects a named range of characters. selections are used to highlight
  # chunks of text that you can refer to later. by giving them a name it's like
  # having a clipboard with multiple clips on it.
  #
  # sym: the name of the selection
  # char_range: a Range representing the starting and ending char of the
  #   selection
  def select(sym, char_range)
    @selections[sym] = char_range

    nil
  end

  # deletes a named selection
  #
  # sym: the name of the selection
  # char_range: a Range representing the starting and ending char of the
  #   selection
  def unselect(sym)
    @selections.delete(sym)

    nil
  end

  def insert!(char)
    @history << [:ins, char, [caret[0], caret[1]]]
    @lines[caret[1]].insert(caret[0], char)
    @bytes += char.bytesize
    @chars += char.length
    @caret[0] += char.length
    modified!

    nil
  end

  def newline!
    active_line = line_at(caret[1])
    upto, after = [active_line[...caret[0]], active_line[caret[0]..]]

    @lines[caret[1]] = upto
    caret[0] = 0
    caret[1] += 1
    @lines.insert(caret[1], after)
    adjust_rect!
    modified!
  end

  def backspace!
    return if caret == [0, 0]

    if caret[0] == 0    # I'm at the beginning of a line
      line_to_move = @lines.delete_at(caret[1])
      @caret = [@lines[caret[1] - 1].length, caret[1] - 1]
      @lines[caret[1]] += line_to_move
    else
      index_to_delete = caret[0] - 1
      char_removed = char_at(caret[0] - 1, caret[1])

      @history << [:backsp, [caret[0] - 1, caret[1]], char_removed]
      @lines[caret[1]] = @lines[caret[1]][...index_to_delete] + @lines[caret[1]][(index_to_delete + 1)..]
      @bytes -= char_removed.bytesize
      @chars -= char_removed.length
      @caret[0] -= 1
    end

    modified!

    nil
  end

#  # deletes and returns the last line of this buffer
#  def pop
#    l = @lines.pop
#    @bytes -= l.bytesize
#    @chars -= l.length
#
#    nil
#  end
#
#  # line: the line to be added to the beginning of the buffer
#  def unshift(line)
#    @lines.unshift(line)
#    @bytes += line.bytesize
#    @chars += line.length
#
#    nil
#  end
#  alias >> unshift
#
#  # deletes and returns the first line of the buffer
#  def shift
#    l = @lines.shift
#    @bytes -= l.bytesize
#    @chars -= l.length
#  end
end
