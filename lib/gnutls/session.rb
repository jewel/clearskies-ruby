require_relative '../buffered_io'
require 'securerandom'

class GnuTLS::Session
  include BufferedIO

  def initialize ptr, direction
    @session = ptr
    @direction = direction
    self.priority = "PFS:+SRP"
    @buffer = String.new
  end

  def bye
    GnuTLS.bye @session, :shut_rdrw
  end

  def handshake
    loop do
      res = GnuTLS.handshake(@session)
      $stderr.puts "successful handshake" if res == 0
      return if res == 0

      if GnuTLS.error_is_fatal(res) != 0
        raise GnuTLS::Error.new("failed handshake #{res}", res) unless res.zero?
      else
        warn "handshake problem (status #{res})" unless res.zero?
      end
    end
  end

  def handshake_timeout=(ms)
    GnuTLS.handshake_set_timeout(@session, ms)
  end

  def priority=(priority_str)
    GnuTLS.priority_set_direct(@session, priority_str, nil)
  end

  def socket= socket
    @socket = socket

    @pull_function = Proc.new { |_, data, maxlen|
      d = nil
      begin
        d = @socket.readpartial maxlen
      rescue EOFError
        d = ""  # signal EOF, we'll catch it again on the other side
      end
      data.write_bytes d, 0, d.size

      d.size
    }

    @push_function = Proc.new { |_, data, len|
      str = data.read_bytes len
      @socket.write str

      str.size
    }

    GnuTLS.transport_set_pull_function @session, @pull_function

    GnuTLS.transport_set_push_function @session, @push_function

    handshake
  end

  def creds= mycreds
    username,password = mycreds
    creds = nil

 

    FFI::MemoryPointer.new :pointer do |creds_out|
      allocator = "srp_allocate_#{@direction}_credentials"

      res = GnuTLS.send allocator, creds_out
      raise "Cannot allocate credentials" unless res == 0

      creds = creds_out.read_pointer
    end

    if @direction == :client
      setter = "srp_set_#{@direction}_credentials"

      res = GnuTLS.send setter, creds, username, password
      raise "Can't #{setter}" unless res == 0
    else
      @server_creds_function = Proc.new { |_,verify_username,salt_p,verifier_p,generator_p,prime_p|
        # ignore username
        begin
          salt = GnuTLS::Datum.new salt_p
          generator = GnuTLS::Datum.new generator_p
          prime = GnuTLS::Datum.new prime_p

          #FIXME How long should this salt be???
          salt_s = SecureRandom.random_bytes 8
          salt[:data] = GnuTLS::LibC.malloc salt_s.size
          salt[:data].write_bytes salt_s, 0, salt_s.size
          salt[:size] = salt_s.size

          generator.copy GnuTLS.srp_2048_group_generator
          prime.copy GnuTLS.srp_2048_group_prime

          err = GnuTLS.srp_verifier username, password, salt, generator, prime, verifier_p
          raise "Can't create verifier" unless err == 0

        rescue
          # FIXME Bubble exception back to C code somehow
          warn "EXCEPTION in callback: #$!"
          exit -1
        end

        if username == verify_username.to_s
          0
        else
          -1
        end
      }

      GnuTLS.srp_set_server_credentials_function creds, @server_creds_function
    end

    res = GnuTLS.credentials_set @session, :crd_srp, creds
    raise "Can't credentials_set with SRP" unless res == 0

    [username, password]
  end

  def write str
    total = 0

    pointer = str_to_buffer str

    while total < str.size
      sent = GnuTLS.record_send @session, pointer + total, str.size - total
      if sent == 0
        # FIXME What does this mean?
        raise "Sent returned zero"
      elsif sent < 0
        raise GnuTLS::Error.new( "cannot send", sent )
      end
      total += sent
    end

    pointer.free
    nil
  end

  def unbuffered_readpartial len
    buffer = FFI::MemoryPointer.new :char, len

    res = GnuTLS.record_recv @session, buffer, len
    if res == -9
      # This error is "A TLS packet with unexpected length was received."
      # This almost certainly means that the connection was closed.
      raise EOFError.new
    elsif res < 0
      raise GnuTLS::Error.new("can't readpartial", res) unless res.zero?
    elsif res == 0
      raise "recv got zero"
    end

    buffer.read_bytes res
  ensure
    buffer.free
  end
  private :unbuffered_readpartial

  def deinit
    # FIXME How do we ensure this is called?
    GnuTLS.deinit(@session)
  end

  private
  def str_to_buffer str
    # Note that this will get garbage collected, so keep a permanent reference
    # around if that is undesirable
    pointer = FFI::MemoryPointer.new(:char, str.size)
    pointer.write_bytes str
    pointer
  end
end
