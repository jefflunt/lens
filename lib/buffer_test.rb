require 'minitest/autorun'
require 'rouge'
require_relative './buffer'

class TestBuffer < Minitest::Test
  def setup
    @content = "line 1\nline 2\nline 3\nline 4\nline 5\nline 6"
    @formatter = Rouge::Formatters::Terminal256.new
    @lexer = Rouge::Lexers::Ruby.new
    @buff = Buffer.new(@formatter, @lexer)
    @content.lines.each{|l| @buff << l }
    @buff.rect = [0, 0, 40, 20]
  end

  # r = rows
  # c = columns
  # w = width
  # h = height
  # together they are the visible rectangle
  def test_rcwh_and_scroll
    assert_equal 0, @buff.r
    assert_equal 0, @buff.c
    assert_equal 40, @buff.w
    assert_equal 20, @buff.h

    assert_equal 0, @buff.r
    assert_equal 0, @buff.c
    assert_equal 40, @buff.w
    assert_equal 20, @buff.h

    @buff.rect_down!

    assert_equal 1, @buff.r
    assert_equal 0, @buff.c
    assert_equal 40, @buff.w
    assert_equal 20, @buff.h

    @buff.rect_down!

    assert_equal 2, @buff.r
    assert_equal 0, @buff.c
    assert_equal 40, @buff.w
    assert_equal 20, @buff.h
  end

  def test_caret_and_rect_adjustments
    # upon initialization, visual caret is in top-left corner of rect, adjusted
    # for the line number display
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # when the rect moves to a place where the visual caret is no longer in the
    # rect, the visual caret moves with the top-left corner of the
    # rect, adjusted for the line number display
    @buff.rect = [1, 1, 40, 20]
    assert_equal [1, 1, 40, 20], @buff.rect
    assert_equal [1, 1], @buff.caret          # the global coordinates move with the rectangle
    assert_equal [2, 0], @buff.screen_caret   # the screen-local coordinates keep the caret in the upper-left

    # this reset of the visual caret applies across multiple moves
    @buff.rect = [2, 2, 40, 20]
    assert_equal [2, 2, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # when the caret position doesn't need to be updated, but the rect moves,
    # then the visual caret location may move with it
    @buff.rect = [0, 0, 40, 20]
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [4, 2], @buff.screen_caret
  end

  def test_caret_and_relative_buff_adjustments
    # upon initialization, visual caret is in top-left corner of rect, adjusted
    # for the line number display
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # when the rect moves to a place where the visual caret is no longer in the
    # rect, the visual caret moves with the top-left corner of the rect,
    # adjusted for the line number display
    @buff.rect_down!
    assert_equal [0, 1, 40, 20], @buff.rect
    assert_equal [0, 1], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    @buff.rect_down!
    assert_equal [0, 2, 40, 20], @buff.rect
    assert_equal [0, 2], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # this reset of the visual caret applies across multiple moves
    @buff.rect_right!
    assert_equal [1, 2, 40, 20], @buff.rect
    assert_equal [1, 2], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    @buff.rect_right!
    assert_equal [2, 2, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # when the caret position doesn't need to be updated, but the rect moves,
    # then the visual caret location may move with it
    @buff.rect_up!
    assert_equal [2, 1, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [2, 1], @buff.screen_caret

    @buff.rect_up!
    assert_equal [2, 0, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [2, 2], @buff.screen_caret

    @buff.rect_left!
    assert_equal [1, 0, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [3, 2], @buff.screen_caret

    @buff.rect_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [4, 2], @buff.screen_caret

    # move just the caret around
    @buff.caret_up!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 1], @buff.caret
    assert_equal [4, 1], @buff.screen_caret

    @buff.caret_up!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 0], @buff.caret
    assert_equal [4, 0], @buff.screen_caret

    # when the caret is already as far as it can go in a given direction,
    # nothing changes
    @buff.caret_up!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 0], @buff.caret
    assert_equal [4, 0], @buff.screen_caret

    @buff.caret_down!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 1], @buff.caret
    assert_equal [4, 1], @buff.screen_caret

    @buff.caret_down!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 2], @buff.caret
    assert_equal [4, 2], @buff.screen_caret

    @buff.caret_down!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 3], @buff.caret
    assert_equal [4, 3], @buff.screen_caret

    @buff.caret_right!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [3, 3], @buff.caret
    assert_equal [5, 3], @buff.screen_caret

    @buff.caret_right!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [4, 3], @buff.caret
    assert_equal [6, 3], @buff.screen_caret

    @buff.caret_right!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [5, 3], @buff.caret
    assert_equal [7, 3], @buff.screen_caret

    # can't go any further to the right, so the coordinates don't change
    @buff.caret_right!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [6, 3], @buff.caret
    assert_equal [8, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [5, 3], @buff.caret
    assert_equal [7, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [4, 3], @buff.caret
    assert_equal [6, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [3, 3], @buff.caret
    assert_equal [5, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [2, 3], @buff.caret
    assert_equal [4, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [1, 3], @buff.caret
    assert_equal [3, 3], @buff.screen_caret

    @buff.caret_left!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [0, 3], @buff.caret
    assert_equal [2, 3], @buff.screen_caret

    @buff.caret_up_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    @buff.caret_left_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    @buff.caret_right_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [5, 0], @buff.caret
    assert_equal [7, 0], @buff.screen_caret

    @buff.caret_down_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [5, 5], @buff.caret
    assert_equal [7, 5], @buff.screen_caret

    # we're already at the bottom
    @buff.caret_down_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [5, 5], @buff.caret
    assert_equal [7, 5], @buff.screen_caret

    # we're already all the way to the right
    @buff.caret_right_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [8, 5], @buff.screen_caret

    # panning
    @buff.rect_right_fast!
    assert_equal [5, 0, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [3, 5], @buff.screen_caret

    @buff.rect_down_fast!
    assert_equal [5, 5, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [3, 0], @buff.screen_caret

    @buff.rect_left_fast!
    assert_equal [0, 5, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [8, 0], @buff.screen_caret

    @buff.rect_up_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [8, 5], @buff.screen_caret

    # cannot pan beyond the limit
    @buff.rect_up_fast!
    assert_equal [0, 0, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [8, 5], @buff.screen_caret

    @buff.rect_down_fast!
    @buff.rect_down_fast!
    @buff.rect_right_fast!
    @buff.rect_right_fast!
    assert_equal [5, 5, 40, 20], @buff.rect
    assert_equal [6, 5], @buff.caret
    assert_equal [3, 0], @buff.screen_caret

    # reveal a bit of the last line
    @buff.rect_left!(3)
    @buff.rect_up!(3)

    assert_equal @buff.rect_s.join("\n"), "3 \e[38;5;230m\e[39m\e[38;5;230mne\e[39m\e[38;5;230m \e[39m\e[38;5;212;01m3\e[39;00m\e[38;5;230m\e[39m\e[0m\e[0K\n4 \e[38;5;230m\e[39m\e[38;5;230mne\e[39m\e[38;5;230m \e[39m\e[38;5;212;01m4\e[39;00m\e[38;5;230m\e[39m\e[0m\e[0K\n5 \e[38;5;230m\e[39m\e[38;5;230mne\e[39m\e[38;5;230m \e[39m\e[38;5;212;01m5\e[39;00m\e[38;5;230m\e[39m\e[0m\e[0K\n6 \e[38;5;230m\e[39m\e[38;5;230mne\e[39m\e[38;5;230m \e[39m\e[38;5;212;01m6\e[39;00m\e[0m\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K\n\e[0K"
  end

  def test_substr_with_color
    input = "\e[31mHello \e[32mWorld\e[0m!\n"
    #                              1     11   indexes of printable characters
    #              012345      67890     12
    assert_equal "\e[31m\e[32morld\e[0m", @buff.substr_with_color(input, 7, 10)
    assert_equal "\e[31mlo \e[32mW\e[0m", @buff.substr_with_color(input, 3, 6)
    assert_equal "\e[31m\e[32morld\e[0m!\e[0m", @buff.substr_with_color(input, 7, 99)
  end

  # visible lines are the number of lines from the buffer's content that are
  # visible at any particular point. for example, if you have a 100-line fail
  # and a buffer that's only 10 lines tall, then unless you scroll past the end
  # of the file then there will always be 10 of the 100 lines visible.
  def test_visible_lines
    assert_equal 6, @buff.visible_lines

    @buff.rect_down!
    assert_equal 5, @buff.visible_lines

    @buff.rect_down!
    assert_equal 4, @buff.visible_lines

    @buff.rect_down!
    assert_equal 3, @buff.visible_lines

    @buff.rect_down!
    assert_equal 2, @buff.visible_lines

    @buff.rect_down!
    assert_equal 1, @buff.visible_lines

    @buff.rect_down! # cannot scroll past the last line
    assert_equal 1, @buff.visible_lines

    @buff.rect = [0, 0, @buff.w, 1]
    assert_equal 1, @buff.visible_lines

    @buff.rect_down!
    assert_equal 1, @buff.visible_lines

    @buff.rect_down!
    assert_equal 1, @buff.visible_lines

    @buff.rect_down! # cannot scroll past the last line
    assert_equal 1, @buff.visible_lines
  end

  # blank lines are the number of lines that don't contain buffer content. for
  # example, if you have a buffer that is 100 lines tall, but it's displaying a
  # file that only contains 10 linues of text, then 90 of the 100 lines will be
  # blank.
  def test_blank_lines
    assert_equal 14, @buff.blank_lines

    @buff.rect_down!
    assert_equal 15, @buff.blank_lines

    @buff.rect_down!
    assert_equal 16, @buff.blank_lines

    @buff.rect_down!
    assert_equal 17, @buff.blank_lines

    @buff.rect_down!
    assert_equal 18, @buff.blank_lines

    @buff.rect_down!
    assert_equal 19, @buff.blank_lines

    @buff.rect_down! # cannot scroll past the last line
    assert_equal 19, @buff.blank_lines

    @buff.rect = [0, 0, @buff.w, 1]
    assert_equal 0, @buff.r
    assert_equal 0, @buff.blank_lines

    @buff.rect_down!
    assert_equal 1, @buff.r
    assert_equal 0, @buff.blank_lines

    @buff.rect_down!
    assert_equal 2, @buff.r
    assert_equal 0, @buff.blank_lines

    @buff.rect_down! # cannot scroll past the last line
    assert_equal 3, @buff.r
    assert_equal 0, @buff.blank_lines
  end

  def test_mark_and_unmark
    @buff.mark(:within_length_range, 3)
    assert_equal 3, @buff.marks[:within_length_range]

    @buff.mark(:outside_length_range, 99)
    assert_equal 36, @buff.marks[:outside_length_range]

    assert_nil @buff.marks[:invalid_mark]
    assert_equal({within_length_range: 3, outside_length_range: 36}, @buff.marks)

    @buff.unmark(:within_length_range)
    @buff.unmark(:outside_length_range)
    @buff.unmark(:invalid_mark)

    assert_nil @buff.marks[:within_length_range]
    assert_nil @buff.marks[:outside_length_range]
    assert_nil @buff.marks[:invalid_mark]
    assert_equal({}, @buff.marks)
  end

  def test_select_and_unselect
    assert_equal({}, @buff.selections)

    @buff.select(:sel1, 3..20)
    assert_equal({sel1: 3..20}, @buff.selections)

    @buff.select(:sel2, 4..15)
    assert_equal({sel1: 3..20, sel2: 4..15}, @buff.selections)

    @buff.unselect(:invalid_unselect)
    assert_equal({sel1: 3..20, sel2: 4..15}, @buff.selections)

    @buff.unselect(:sel1)
    assert_equal({sel2: 4..15}, @buff.selections)

    @buff.unselect(:sel2)
    assert_equal({}, @buff.selections)
  end

  def test_insert_backspace_replace_and_history
    assert_equal [], @buff.history
    assert_equal 36, @buff.bytes
    assert_equal 36, @buff.chars
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    @buff.insert!('a')
    assert_equal [:ins, 'a', [0, 0]], @buff.history.last
    assert_equal 'aline 1', @buff.line_at(@buff.caret[1])
    assert_equal 37, @buff.bytes
    assert_equal 37, @buff.chars
    assert_equal [1, 0], @buff.caret
    assert_equal [3, 0], @buff.screen_caret

    @buff.backspace!
    assert_equal [:backsp, [1, 0]], @buff.history.last
    assert_equal 'line 1', @buff.line_at(@buff.caret[1])
    assert_equal 36, @buff.bytes
    assert_equal 36, @buff.chars
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret

    # can't backspace when you're at the beginning of the line already
    @buff.backspace!
    assert_equal [:backsp, [1, 0]], @buff.history.last
    assert_equal 'line 1', @buff.line_at(@buff.caret[1])
    assert_equal 36, @buff.bytes
    assert_equal 36, @buff.chars
    assert_equal [0, 0], @buff.caret
    assert_equal [2, 0], @buff.screen_caret
  end
end
