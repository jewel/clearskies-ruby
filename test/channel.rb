
require 'tempfile'
require 'socket'
require 'securerandom'

# This is a testing library intended to be a drop in replacement for the real
# channel clearskies library.
#
# Instead of following the spec, this simply uses a unix domain socket for the
# channel.  The path the to socket is the channel_id and the access_code.
class Channel
  attr_reader :channel_id

  def initialize name, socket_path=nil
    @name = name
    @clients = []
    if socket_path
      @channel_id = socket_path
      @clients.push [UNIXSocket.new(@channel_id), ""]
      @is_server = false
    else
      @channel_id = Dir::Tmpname.make_tmpname "/tmp/clearskies_test", nil
      @server = UNIXServer.new @channel_id
      @is_server = true
    end
    @peerid = SecureRandom.hex 128/8 # 128 bits/8 bits-per-byte
  end

  def access_code
    @channel_id
  end

  def self.join_channel socket_path
    self.new "Joined channel", socket_path
  end

  # must be non blocking!
  def read_message
    if @is_server
      begin
        @clients.push [@server.accept_nonblock, ""]
      rescue IO::WaitReadable, Errno::EINTR
      end
    end
    @clients.each do |socket, buffer|
      begin
        # Inspired by: http://stackoverflow.com/a/20883716
        buffer << socket.read_nonblock(1) while buffer[-1] != "\n"
        i = buffer.dup
        buffer.clear
        return i
      rescue IO::WaitReadable
      end
    end
    return nil
  end

  def list_peers
    return @clients # TODO: definitely don't return the sockets
  end

  def send_message message
    @clients.each do |socket,buffer|
      socket.puts message
    end
  end
end
