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
require 'yaml'
require_relative './lib/config'

config = Config.new(YAML.load(IO.read('config.yml')))

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
mode = 'home'
cmd = nil

loop do
  print caret.hide
  print caret.move_to(0, 0)
  puts fb.win_s
  print "#{(mode.upcase + " #{cmd}").ljust(16).black.on_white} [#{fb.win.map{|i| i + 1}.join(', ')}] v:#{fb.visible_lines}, b:#{fb.blank_lines} -- vlines #{fb.win_s.length} -- lw:#{fb.line_no_width} | ^#{fb.caret.map{|n| n + 1 }.join(', ')} | v^[#{fb.visual_caret.map{|n| n + 1 }.join(', ')}]\e[0K"

  # visual caret repositioning
  print caret.move_to(*fb.visual_caret)
  print caret.show

  c = $stdin.getch
  cmd = config.cmd(mode, nil, c)

  case cmd
  when Symbol
    cmd = config.cmd(mode, cmd, $stdin.getch)
  when nil
    print "\a"
  end

  break if cmd == 'exit'
  # handle cmd

  c_rows, c_cols = console.winsize
  fb.win = [fb.c, fb.r, c_cols, c_rows - 1]
end

puts 'bye'
