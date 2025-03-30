# a text buffer with marks, selections, and rudimentary editing
class Buffer
  attr_reader :chars,
              :bytes,
              :lines,
              :length,
              :line_no_width,
              :max_char_width,
              :win,
              :caret,
              :marks,
              :selections

  # gives you a default, empty, zero slice
  #
  # formatter - a Rouge formatter
  # lexer - a Rouge lexer
  def initialize(formatter, lexer)
    @formatter = formatter
    @lexer = lexer
    @win = [0, 0, 0, 0]    # the default slice is at the beginning of the buffer, and has a zero size
    @caret = [c, r]

    # size tracking
    @chars = 0        # the number of characters in the buffer (not the same as the number of bytes)
    @bytes = 0        # the number of bytes in the buffer (not the same as the number of characters)
    @lines = []
    @line_no_width = 1
    @rendered_lines = [] # fully formatted, syntax highlighted, and transformed
    @edited_since_last_render = true
    @max_char_width = 0
    @all_buff = @lines.join("\n")

    @marks = {}
    @selections = {}
  end

  # move the buffer's visible coordinates, and possibly the caret as well, if
  # moving the window would cause the caret to be out-of-bounds
  def rect=(coords)
    @win = coords

    adjust_caret!
  end

  # index of first visible column
  def c
    @win[0]
  end

  # index of first visible row
  def r
    @win[1]
  end

  # width of the buffer window
  def w
    @win[2]
  end

  # height of the buffer window
  def h
    @win[3]
  end

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

  def adjust_win!
    cx, cy = visual_caret
    wx, wy = @win[0], @win[1]

    new_wx = if cx > (c + w - 1)
               wx + 1
             elsif cx < 0
               wx - 1
             else
               wx
             end

    new_wy = if cy > (r + h - 1)
               wy + 1
             elsif cy < 0
               wy - 1
             else
               wy
             end

    @win[0] = wx
    @win[1] = wy
  end

  def caret_down!
    @caret[1] = [caret[1] + 1, @lines.length - 1].min
    adjust_win!
  end

  def caret_up!
    @caret[1] = [caret[1] - 1, 0].max
    adjust_win!
  end

  def caret_left!
    @caret[0] = [caret[0] - 1, 0].max
    adjust_win!
  end

  def caret_right!
    @caret[0] = [caret[0] + 1, @lines[caret[1]].length - 1].min
    adjust_win!
  end

  # you can think the caret position as the exact (x, y) position within a file
  # as a whole (like world coordinates within a video game), but the
  # visual_caret as the (x, y) position within the rendered portion of the
  # buffer (similar to screen coordinates within a buffer), but also offset by
  # the width of the line numbers.
  def visual_caret
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
    if @edited_since_last_render
      @rendered_lines = @formatter
        .format(
          @lexer.lex(
            @lines.join("\n")
          )
        )
        .lines
        .map(&:chomp)

      @edited_since_last_render = false
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

  # the number of blank lines in the buffer after showing all visible lines
  def blank_lines
    [@win[3] - visible_lines, 0].max
  end

  # scrolls the visible window up
  def buff_up!(n=1)
    @win[1] = [@win[1] - n, 0].max
    adjust_caret!
  end

  # scrolls the visible window down
  def buff_down!(n=1)
    @win[1] = [@win[1] + n, @lines.length - 1].min
    adjust_caret!
  end

  # scrolls the visible window left
  def buff_left!(n=1)
    @win[0] = [@win[0] - n, 0].max
    adjust_caret!
  end

  # scrolls the visible window right
  def buff_right!(n=1)
    @win[0] = [@win[0] + n, max_char_width - 1].min
    adjust_caret!
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

  # line: the line to add to the end of the buffer
  def <<(line)
    line.chomp!
    @lines << line
    @bytes += line.length
    @chars += line.chars.length
    @max_char_width = line.chars.length if line.chars.length > @max_char_width

    @edited_since_last_render = true
    nil
  end
#
#  # deletes and returns the last line of this buffer
#  def pop
#    l = @lines.pop
#    @bytes -= l.length
#    @chars -= l.chars.length
#
#    nil
#  end
#
#  # line: the line to be added to the beginning of the buffer
#  def unshift(line)
#    @lines.unshift(line)
#    @bytes += line.length
#    @chars += line.chars.length
#
#    nil
#  end
#  alias >> unshift
#
#  # deletes and returns the first line of the buffer
#  def shift
#    l = @lines.shift
#    @bytes -= l.length
#    @chars -= l.chars.length
#  end
end
