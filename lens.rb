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
require 'pry'
require 'io/console'
require 'tty-cursor'
require 'rouge'
require 'tiny_color'
require 'yaml'
require 'rouge'
require_relative './cmds'
require_relative './lib/config'
require_relative './lib/buffer'

config = Config.new(YAML.load(IO.read('config.yml')))

buff = Buffer.new(
  Rouge::Formatters::Terminal256.new,
  Rouge::Lexers::Ruby.new
)

IO
  .readlines(ARGV.shift)
  .each{|l| buff << l.chomp }

console = IO.console
c_rows, c_cols = console.winsize
c_rows -= 1
buff.win = [0, 0, c_cols, c_rows]
caret = TTY::Cursor
default_mode = config.default_mode
mode = default_mode
cmd_char = nil        # cmd_char is the literal character read back from the keyboard
cmd = nil             # this is the command to execute, or subcommand to ready
cmd_str = cmd.to_s    # this is the command to execute

loop do
  print caret.hide
  print caret.move_to(0, 0)
  puts buff.win_s
  print "#{("#{mode.upcase} #{cmd_char&.ord} #{cmd_str}").ljust(30).black.on_white}\e[0K"

  cmd_char = nil
  cmd = nil
  cmd_str = cmd.to_s

  # visual caret repositioning
  print caret.move_to(*buff.visual_caret)
  print caret.show

  # cmd input and a couple of special cases
  cmd_char = $stdin.getch
  cmd = config.cmd(mode, nil, cmd_char)

  break if cmd == 'exit'
  ((mode = default_mode) && next) if cmd_char&.ord == 27  # esc key

  # handle cmds
  case cmd
  when Symbol     # ready subcmd
    cmd = config.cmd(mode, cmd, $stdin.getch)
    cmd_str = cmd
  when Array      # wildcard
  when String     # direct
    case mode
    when default_mode
      if buff.respond_to?(cmd)
        buff.send(cmd)
      elsif Cmds.respond_to?(cmd)
        Cmds.send(cmd)
      elsif cmd.start_with?('ms_')
        mode = cmd.sub('ms_', '')
      else
        print "\a"
      end
    end
  when nil        # cmd not found
    print "\a"
  end

  c_rows, c_cols = console.winsize
  buff.win = [buff.c, buff.r, c_cols, c_rows - 1]
end

# TODO: shutdown the buffer proxy
puts 'bye'
