CTRL_C = 3

unless ARGV.length == 1 && File.exist?(ARGV.first)
  puts <<~USAGE
    ERR: You must specify a filename

    Ex:
      ruby lens.rb <filename>
  USAGE

  exit 1
end

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
cursor = TTY::Cursor

Thread.new do
  loop do
    c_rows, c_cols = console.winsize
    fb.win = [fb.r, fb.c, c_cols, c_rows - 1]

    sleep 0.5
  end
end

loop do
  print cursor.move_to(0, 0)
  puts fb.win_s
  print " #{'CMD'.black.on_white} [#{fb.win.map{|i| i + 1}.join(', ')}] v:#{fb.visible_lines}, b:#{fb.blank_lines} -- #{fb.win_s.length}\r"

  c = $stdin.getch
  break if c.ord == CTRL_C

  case c.ord
  when 74 # J
    fb.win_down
  when 75 # K
    fb.win_up
  when 72 # H
    fb.win_left
  when 76 # L
    fb.win_right
  end
end

puts 'bye'
