# these requires statements are placed after the USAGE cheack above so that the
# error situation can be faster than the happy path
require 'pry'
require 'io/console'
require 'tty-cursor'
require 'rouge'
require 'tiny_color'
require 'yaml'
require 'rouge'
require 'tiny_log'
require 'nobject/local'
require 'nobject/server'
require_relative './cmds'
require_relative './lib/config'
require_relative './lib/buffer'

config = Config.new(YAML.load(IO.read('config.yml')))

# start buffer server
BUFF_SERVER_PORT = rand(63535) + 1000
buff_server = Nobject::Server.new(BUFF_SERVER_PORT)
log = TinyLog.new(filename: '/tmp/lens.log', buffering: false, background_thread: false)

Thread.new { buff_server.start! }

filename = ARGV.shift
buff = Nobject::Local.new(
  'localhost',
  BUFF_SERVER_PORT,
  Buffer.new(
    Rouge::Formatters::Terminal256.new,
    Rouge::Lexer.guess_by_filename(filename),
    filename
  )
)

console = IO.console
c_rows, c_cols = console.winsize
c_rows -= 1                         # to leave space for the status line
buff.rect = [0, 0, c_cols, c_rows]
log.buff([c_cols, c_rows].join(','))
log.buff(buff.rect.join(', '))
caret = TTY::Cursor
default_mode = config.default_mode
mode = default_mode
cmd_char = nil        # cmd_char is the literal character read back from the keyboard
cmd = nil             # this is the command to execute, or subcommand to ready
cmd_str = cmd.to_s    # this is the command to execute

loop do
  print caret.hide
  print caret.move_to(0, 0)
  puts buff.rect_s
  print "#{("#{mode.upcase} #{cmd_char&.ord} #{cmd_str}").ljust(30).black.on_white}\e[0K #{buff.bytes}"

  cmd_char = nil
  cmd = nil
  cmd_str = cmd.to_s

  # visual caret repositioning
  print caret.move_to(*buff.screen_caret)
  print caret.show

  # cmd input and a couple of special cases
  cmd_char = $stdin.getch
  cmd = config.cmd(mode, nil, cmd_char)

  break if cmd == 'exit'
  if cmd_char&.ord == 27  # esc key
    mode = default_mode
    buff.save
    next
  end

  case mode
  when 'insert'
    case cmd_char.ord
    when 9    # tab
      (buff.caret[0] % 2 == 0) ?
        buff.insert!('  ') :
        buff.insert!(' ')
    when 13   # enter
      buff.newline!
    when 127  # backspace
      buff.backspace!
    else
      buff.insert!(cmd_char)
    end
  else
    # handle cmds
    case cmd
    when Symbol     # ready subcmd
      cmd = config.cmd(mode, cmd, $stdin.getch)
      cmd_str = cmd
    when Array      # wildcard
      buff.send(cmd.first, *cmd[1..])
    when String     # direct
      if cmd.start_with?('ms_')
        mode = cmd.sub('ms_', '')
      elsif Cmds.respond_to?(cmd)
        Cmds.send(cmd)
      else
        buff.send(cmd)
      end
    when nil        # cmd not found
      print "\a"
    end
  end
  log.cmd("#{cmd.nil? ? 'nil' : cmd} c[#{buff.caret.join(', ')}] sc[#{buff.screen_caret.join(', ')}] w[#{buff.rect.join(', ')}]")

  c_rows, c_cols = console.winsize
  buff.rect = [buff.c, buff.r, c_cols, c_rows - 1]
end

# TODO: shutdown the buffer proxy
puts 'bye'