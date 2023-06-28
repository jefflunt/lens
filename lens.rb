CTRL_C = 3

unless ARGV.length == 1 && File.exist?(ARGV.first)
  puts <<~USAGE
    ERR: You must specify a filename

    Ex:
      ruby lens.rb <filename>
  USAGE

  exit 1
end

# these requires statements are placed after the USAGE cheack above so that the
# error situation can be faster than the happy path
require 'io/console'
require 'tty-cursor'
require 'fancy_buff'
require 'rouge'
require 'tiny_color'

fb = FancyBuff.new(
  Rouge::Formatters::Terminal256.new,
  Rouge::Lexers::Ruby.new
)

IO
  .read(ARGV.shift)
  .lines
  .map(&:chomp)
  .each{|l| fb << l }

console = IO.console
c_rows, c_cols = console.winsize
c_rows -= 1
fb.win = [0, 0, c_cols, c_rows]
caret = TTY::Cursor

loop do
  print caret.hide
  print caret.move_to(0, 0)
  puts fb.win_s
  print "#{'CMD'.black.on_white} [#{fb.win.map{|i| i + 1}.join(', ')}] v:#{fb.visible_lines}, b:#{fb.blank_lines} -- vlines #{fb.win_s.length} -- lw:#{fb.line_no_width} | ^#{fb.caret.map{|n| n + 1 }.join(', ')} | v^[#{fb.visual_caret.map{|n| n + 1 }.join(', ')}]\e[0K"

  # visual caret repositioning
  print caret.move_to(*fb.visual_caret)
  print caret.show

  c = $stdin.getch
  break if c.ord == CTRL_C

  case c.ord
  when 74 # J
    fb.win_down!
  when 75 # K
    fb.win_up!
  when 72 # H
    fb.win_left!
  when 76 # L
    fb.win_right!
  when 106 # j
    fb.caret_down!
  when 107 # k
    fb.caret_up!
  when 104 # h
    fb.caret_left!
  when 108 # l
    fb.caret_right!
  end

  c_rows, c_cols = console.winsize
  fb.win = [fb.c, fb.r, c_cols, c_rows - 1]
end

puts 'bye'
