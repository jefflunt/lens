require 'socket'
require_relative './buffer'

class BufferServer
  attr_reader :buffer 

  def initialize
    @buffer = Buffer.new(
      Rouge::Formatters::Terminal256.new,
      Rouge::Lexers::Ruby.new
    )
  end

  def load!(path)
    IO
      .readlines(path)
      .each{|l| @buffer << l.chomp }
  end
end
