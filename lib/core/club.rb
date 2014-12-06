

class Club
  attr_reader :peerid
  def initialize name
    @name = name
    @read_ac = []
    @write_ac = []
    @read_key = CommunicationKey.new
    @write_key = CommunicationKey.new
    @read_key_sig = SignatureKey.new
    @write_key_sig = SignatureKey.new
    @peerid = SecureRandom.hex 128/8 # 128 bits/8 bits-per-byte
  end

  def join_club access_code_str
    ac = AccessCode.parse access_code_str
  end
    

  def add_access_code ac, level
    case level
    when :read
      @read_ac.push ac
    when :write
      @write_ac.push ac
    else
      abort "Invalid access code level #{level}"
    end
  end
end
