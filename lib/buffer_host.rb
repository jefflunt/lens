require 'socket'
require 'rouge'
require_relative './buffer'

begin
  host, port = [ARGV.shift, ARGV.shift]
  path = ARGV.shift

  puts "connecting to #{host}:#{port}"
  socket = TCPSocket.new(host, port)

  buffer = Buffer.new(Rouge::Formatters::Terminal256.new, Rouge::Lexer.guess_by_filename(path))
  IO
    .readlines(filename)
    .each{|l| buff << l.chomp }

  loop do
    req = socket.gets.chomp
    puts "REQ: #{req}"
    socket.puts(":ok")
  end
rescue NoMethodError, IOError
  socket&.close
  break
end
