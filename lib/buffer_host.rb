require 'socket'

host, port = [ARGV.shift, ARGV.shift]

puts "connecting to #{host}:#{port}"
socket = TCPSocket.new(host, port)

loop do
  req = socket.gets.chomp
  puts "REQ: #{req}"
  socket.puts(":ok")
rescue NoMethodError, IOError
  socket&.close
end
