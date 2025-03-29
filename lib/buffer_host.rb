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

    buffer_msgr = BufferMsgr.new(socket, true)

    loop do
      opcode, payload = buffer_msgr.recv_any

      case SoaMsgr::OP_TO_PROTO[opcode]
      when 'buffer_close'
        # save file, close socket
        break
      when 'win='
        # set the dimensions of the buffer
      else
        # when 
        break
      end
    end
  end
rescue NoMethodError, IOError
  socket&.close
end
