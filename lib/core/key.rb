
class SignatureKey
  def initialize
    # TODO: bump this to 2048 bits as required by spec
    @key = OpenSSL::PKey::RSA.new(128).to_s
  end
end

class CommunicationKey
  def initialize
    # 256 bits/8 bits-per-byte
    @key = SecureRandom.hex 256/8
    @keyid = SecureRandom.hex 256/8
  end
end
