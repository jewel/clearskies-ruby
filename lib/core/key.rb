require 'openssl'
require 'securerandom'

class CommunicationKey
  def initialize
    # TODO: bump this to 2048 bits as required by spec
    @key = OpenSSL::PKey::RSA.new(128)
  end

  def channel_id
    "Exactly 16 bytes"
  end
end
