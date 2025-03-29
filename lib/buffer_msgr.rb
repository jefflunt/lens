require 'socket'

##
# NOTE: this code is auto-generated from an nmspec file
##
# msgr specification for lens hosted buffers
class BuffermsgrMsgr
  PROTO_TO_OP = {
    'open_path' => 0,
    'set_rect' => 1,
    'get_rect' => 2,
  }

  OP_TO_PROTO = {
    0 => 'open_path',
    1 => 'set_rect',
    2 => 'get_rect',
  }

  def initialize(socket, no_delay=false)
    @socket = socket
    @open = true
    @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if no_delay
  end

  ##
  # closes the socket inside this object
  def open?
    !!(@socket && @open)
  end

  ##
  # closes the socket inside this object
  def close
    @open = false
    @socket&.close
  end

  ###########################################
  # boolean type
  ###########################################

  def r_bool
    @socket.recv(1).unpack('C')[0] == 1
  end

  def w_bool(bool)
    @socket.send([bool ? 1 : 0].pack('C'), 0)
  end

  ###########################################
  # numeric types
  ###########################################

  def r_i8
    @socket.recv(1).unpack('c').first
  end

  def w_i8(i8)
    @socket.send([i8].pack('c'), 0)
  end

  def r_u8
    @socket.recv(1).unpack('C').first
  end

  def w_u8(u8)
    @socket.send([u8].pack('C'), 0)
  end

  def r_i16
    @socket.recv(2).unpack('s>').first
  end

  def w_i16(i16)
    @socket.send([i16].pack('s>'), 0)
  end

  def r_u16
    @socket.recv(2).unpack('S>').first
  end

  def w_u16(u16)
    @socket.send([u16].pack('S>'), 0)
  end

  def r_i32
    @socket.recv(4).unpack('l>').first
  end

  def w_i32(i32)
    @socket.send([i32].pack('l>'), 0)
  end

  def r_u32
    @socket.recv(4).unpack('L>').first
  end

  def w_u32(u32)
    @socket.send([u32].pack('L>'), 0)
  end

  def r_i64
    @socket.recv(8).unpack('q>').first
  end

  def w_i64(i64)
    @socket.send([i64].pack('q>'), 0)
  end

  def r_u64
    @socket.recv(8).unpack('Q>').first
  end

  def w_u64(u64)
    @socket.send([u64].pack('Q>'), 0)
  end

  def r_float
    @socket.recv(4).unpack('g').first
  end

  def w_float(float)
    @socket.send([float].pack('g'), 0)
  end

  def r_double
    @socket.recv(8).unpack('G').first
  end

  def w_double(double)
    @socket.send([double].pack('G'), 0)
  end

  ###########################################
  # str types
  ###########################################

  def r_str
    bytes = @socket.recv(4).unpack('L>').first
    @socket.recv(bytes)
  end

  def w_str(str)
    @socket.send([str.length].pack('L>'), 0)
    @socket.send(str, 0)
  end

  def r_str_list
    strings = []

    @socket.recv(4).unpack('L>').first.times do
      str_length = @socket.recv(4).unpack('L>').first
      strings << @socket.recv(str_length)
    end

    strings
  end

  def w_str_list(str_list)
    @socket.send([str_list.length].pack('L>'), 0)
    str_list.each do |str|
      @socket.send([str.length].pack('L>'), 0)
      @socket.send(str, 0)
    end
  end

  ###########################################
  # list types
  ###########################################

  def r_i8_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 1).unpack('c*')
  end

  def w_i8_list(i8_list)
    @socket.send([i8_list.length].pack('L>'), 0)
    @socket.send(i8_list.pack('c*'), 0)
  end

  def r_u8_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 1).unpack('C*')
  end

  def w_u8_list(u8_list)
    @socket.send([u8_list.length].pack('L>'), 0)
    @socket.send(u8_list.pack('C*'), 0)
  end

  def r_i16_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 2).unpack('s>*')
  end

  def w_i16_list(i16_list)
    @socket.send([i16_list.length].pack('L>'), 0)
    @socket.send(i16_list.pack('s>*'), 0)
  end

  def r_u16_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 2).unpack('S>*')
  end

  def w_u16_list(u16_list)
    @socket.send([u16_list.length].pack('L>'), 0)
    @socket.send(u16_list.pack('S>*'), 0)
  end

  def r_i32_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 4).unpack('l>*')
  end

  def w_i32_list(i32_list)
    @socket.send([i32_list.length].pack('L>'), 0)
    @socket.send(i32_list.pack('l>*'), 0)
  end

  def r_u32_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 4).unpack('L>*')
  end

  def w_u32_list(u32_list)
    @socket.send([u32_list.length].pack('L>'), 0)
    @socket.send(u32_list.pack('L>*'), 0)
  end

  def r_i64_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 8).unpack('q>*')
  end

  def w_i64_list(i64_list)
    @socket.send([i64_list.length].pack('L>'), 0)
    @socket.send(i64_list.pack('q>*'), 0)
  end

  def r_u64_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 8).unpack('Q>*')
  end

  def w_u64_list(u64_list)
    @socket.send([u64_list.length].pack('L>'), 0)
    @socket.send(u64_list.pack('Q>*'), 0)
  end

  def r_float_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 4).unpack('g*')
  end

  def w_float_list(float_list)
    @socket.send([float_list.length].pack('L>'), 0)
    @socket.send(float_list.pack('g*'), 0)
  end

  def r_double_list
    list_len = @socket.recv(4).unpack('L>').first
    @socket.recv(list_len * 8).unpack('G*')
  end

  def w_double_list(double_list)
    @socket.send([double_list.length].pack('L>'), 0)
    @socket.send(double_list.pack('G*'), 0)
  end

  ###########################################
  # subtype aliases
  ###########################################

  alias_method :r_path, :r_str
  alias_method :w_path, :w_str
  alias_method :r_c, :r_u16
  alias_method :w_c, :w_u16
  alias_method :r_r, :r_u16
  alias_method :w_r, :w_u16
  alias_method :r_w, :r_u16
  alias_method :w_w, :w_u16
  alias_method :r_h, :r_u16
  alias_method :w_h, :w_u16
  alias_method :r_rect, :r_u16_list
  alias_method :w_rect, :w_u16_list
  alias_method :r_buff_text, :r_str_list
  alias_method :w_buff_text, :w_str_list
  ###########################################
  # messages
  ###########################################

  # open a file specified by the path
  def send_open_path(path)
    w_u8(0)
    w_path(path)
    []
  end

  # open a file specified by the path
  #
  # returns:  (type | local var name)
  # [
  #    path         | path
  # ]
  def recv_open_path
    path = r_path
    [path]
  end

  # set the dimensions of the buffer's visible rectangle
  def send_set_rect(dimensions)
    w_u8(1)
    w_rect(dimensions)
    []
  end

  # set the dimensions of the buffer's visible rectangle
  #
  # returns:  (type | local var name)
  # [
  #    rect         | dimensions
  # ]
  def recv_set_rect
    dimensions = r_rect
    [dimensions]
  end

  # get the dimen
  def send_get_rect(dimensions)
    w_u8(2)
    w_rect(dimensions)
    []
  end

  # get the dimen
  #
  # returns:  (type | local var name)
  # [
  #    rect         | dimensions
  # ]
  def recv_get_rect
    dimensions = r_rect
    [dimensions]
  end

  # This method is used when you're receiving protocol messages
  # in an unknown order, and dispatching automatically.
  #
  # NOTE: while you can pass parameters into this method, if you know the
  #       inputs to what you want to receive then you probably know what
  #       messages you are getting. In that case, explicit recv_* method calls
  #       are preferred, if possible. However, this method can be very
  #       effective for streaming in read-only protocol messages.
  def recv_any(params=[])
    case @socket.recv(1).unpack('C').first
    when 0 then [0, recv_open_path(*params)]
    when 1 then [1, recv_set_rect(*params)]
    when 2 then [2, recv_get_rect(*params)]
    end
  end
end
