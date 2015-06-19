require 'securerandom'
require_relative 'key'
require_relative 'access_code'

class Channel
  attr_reader :channel_id
  def initialize name
    @name = name
    @comm_key = CommunicationKey.new
    @channel_id = @comm_key.channel_id
    @peerid = SecureRandom.hex 128/8 # 128 bits/8 bits-per-byte
    @channel_secret = SecureRandom.random_bytes 64/8 # 64 bits/8 bits-per-byte
    @access_code = AccessCode.from_channel @channel_id, @channel_secret
  end

  def access_code 
    @access_code.to_s
  end

  def self.join_channel access_code_str
    ac = AccessCode.parse access_code_str
    #FIXME don't just generate a new channel here
    self.new "Joined channel"
  end
end
