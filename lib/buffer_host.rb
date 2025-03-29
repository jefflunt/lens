require 'socket'
require 'rouge'
require 'securerandom'
require_relative './buffer'

begin
  host, port = [ARGV.shift, ARGV.shift]
  path = ARGV.shift

  puts "connecting to #{host}:#{port}"
  socket = TCPSocket.new(host, port)

  buffer = Buffer.new(Rouge::Formatters::Terminal256.new, Rouge::Lexer.guess_by_filename(path))
  `touch #{path}`

  IO
    .readlines(path)
    .each{|l| buff << l.chomp }

  log_filename = "/tmp/buffer.#{SecureRandom.uuid}.log"
  File.open(log_filename, 'w') do |log_file|
    socket.puts log_filename
    loop do
      req = socket.gets.chomp
      cmd, rest = req.split(' ', 2)

      case cmd
      when 'win='
        log_file.puts req
      else
        log_file.puts "err: unknown req #{req}"
        socket.puts 'error/close'
        break
      end

      log_file.flush
    end
  end
rescue NoMethodError, IOError
  socket&.close
end
