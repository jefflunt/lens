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
require_relative './cmds'
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
DEFAULT_MODE = 'buff'
mode = DEFAULT_MODE
cmd_char = nil
cmd = nil
cmd_str = cmd.to_s

loop do
  print caret.hide
  print caret.move_to(0, 0)
  puts fb.win_s
  print "#{(mode.upcase + " #{cmd_char&.ord} #{cmd_str}").ljust(16).black.on_white} [#{fb.win.map{|i| i + 1}.join(', ')}] v:#{fb.visible_lines}, b:#{fb.blank_lines} -- vlines #{fb.win_s.length} -- lw:#{fb.line_no_width} | ^#{fb.caret.map{|n| n + 1 }.join(', ')} | v^[#{fb.visual_caret.map{|n| n + 1 }.join(', ')}]\e[0K"


  cmd_char = nil            # cmd_char is the literal character read back from the keyboard
  cmd = nil                 # this is the command to execute, or subcommand to ready
  cmd_str = cmd.to_s        # this is the command to execute

  # visual caret repositioning
  print caret.move_to(*fb.visual_caret)
  print caret.show

  # cmd input handling and dispatch via the Config instance
  cmd_char = $stdin.getch
  cmd = config.cmd(mode, nil, cmd_char)

  # handle special cmds: escape and exit
  break if cmd == 'exit'
  ((mode = DEFAULT_MODE) && next) if cmd_char&.ord == 27  # esc key

  # handle all other commands
  case cmd
  when Symbol     # ready subcmd
    cmd = config.cmd(mode, cmd, $stdin.getch)
    cmd_str = cmd
  when Array      # wildcard
  when String     # direct
    case mode
    when 'buff'
      if fb.respond_to?(cmd)
        fb.send(cmd)
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
  fb.win = [fb.c, fb.r, c_cols, c_rows - 1]
end

puts 'bye'
