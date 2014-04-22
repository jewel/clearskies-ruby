require_relative '../lib/gnutls'
#GnuTLS.enable_logging
unless GnuTLS.check_version("3.1.4")
  abort "ERROR: Need at least GnuTLS version 3.1.4, current version is #{GnuTLS.check_version("0.0.0")}"
end
require 'minitest/autorun'

# Check for heap corruption
def stress_memory
  100000.times do
    pointer = FFI::MemoryPointer.new(1)
  end
end

def run_test first_tls_class, second_tls_class
  before do
    server = TCPServer.new "localhost", 0
    @port = server.local_address.ip_port

    @server_pid = fork
    next if @server_pid
    begin
      loop do
        socket = server.accept
        if fork
          socket.close
          next
        end
        begin
          tls = first_tls_class.new socket, "longuser", "longlongabcd"
          while data = tls.readpartial(1024)
            tls.write data
          end
        rescue EOFError
        rescue
          warn "Helper process raised exception: #$!"
        end
        exit
      end
    rescue
      warn "helper process raised exception: #$!"
    end
    exit
  end

  after do
    Process.kill :TERM, @server_pid
  end

  it "can connect and send data" do
    begin
      socket = TCPSocket.new "localhost", @port
      tls = second_tls_class.new socket, "longuser", "longlongabcd"
      tls.puts "hehe"
      tls.gets.must_equal "hehe\n"
      tls.puts "hoheho 1234"
      tls.gets.must_equal "hoheho 1234\n"
      1000.times do |i|
        str = "!" * 1024
        tls.write str
        tls.read(1024).must_equal str
      end
      tls.bye
      stress_memory
    rescue 
      # give the child a chance to die
      sleep 1
      raise $!
    end
  end

  it "won't connect with wrong username" do
    socket = TCPSocket.new "localhost", @port
    proc {
      tls = second_tls_class.new socket, "blah", "longlongabcd"
    }.must_raise GnuTLS::Error
  end
  it "won't connect with wrong password" do
    socket = TCPSocket.new "localhost", @port
    proc {
      tls = second_tls_class.new socket, "longuser", "1234"
    }.must_raise GnuTLS::Error
  end
end

describe GnuTLS::Session do
   describe "acts as a server" do
     run_test GnuTLS::Socket, GnuTLS::Server
   end

   #describe "acts as a client" do
   #  run_test GnuTLS::Server, GnuTLS::Socket
   #end
end
