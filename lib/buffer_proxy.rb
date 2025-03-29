require 'socket'

# runs a TCPServer to communicate with connected hosted buffers over the
# network.
#
# manages a number of @responses Queue objects, indexed by their path in a Hash.
# the 'active' response queue is processed first, followed by any response
# queueus that are actively tailing, followed finally by whatever is left, which
# should be mostly passive response queues that don't have much to say.
class BufferProxy
  SERVER_HOST = 'localhost'
  SERVER_PORT = 4685

  def initialize
    @server = TCPServer.new(SERVER_PORT)
    @active_buffer = nil
    @responses = {}
    @clients = {}
    @keep_running = true
  end

  def start!
    loop do
    end
  end

  def stop!
    @keep_running = false
  end

  def send(msg)
    s = @clients[@active_buffer][:socket]
    s.puts msg
    resp = s.gets

    if resp == 'error/close'
      s.close
      @clients.delete(@active_buffer)
    end

    resp
  end

  # marks the named buffer (by its path) as the active buffer, which will
  # prioritize processing its response queue as the top priority.
  def make_active!(path)
    @active_buffer = path
  end

  def spawn_buffer(path)
    Thread.new do
      # spawn a new buffer host and pass the server host and port to it
      # also handle client accept here, since there should be a 1:1 mapping
      # between spawned buffers and connected clients

      puts "spawning hosted buffer for #{path}"
      # spawn a new process
      Process.detach(
        Process.spawn(
          "ruby lib/buffer_host.rb #{SERVER_HOST} #{SERVER_PORT} #{path}"
        )
      )

      @responses[path] = { msgs: Queue.new, type: :passive }
      @active_buffer = path
      s = @server.accept
      _, port, hostname, ip = s.addr

      log_filename = s.gets.chomp
      @clients[path] = {
        socket: s,
        path: path,
        log_filename: log_filename,
      }
      puts "buff.accp path:#{path} log:#{log_filename} addr:#{hostname}:#{ip}:#{port}"
    end
  end

  def close_buffer(path)
    @clients[path]&.close
    puts "closed buffer for #{path}"
  rescue IOError
    @clients.delete(path)
  end
end
