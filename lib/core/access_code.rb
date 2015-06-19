# Class to represent a single access code.
#
# See protocol/core.md for an explanation of access codes.

require_relative 'base32'
require_relative 'luhn_check'
require 'digest/sha2'
require 'securerandom'

# This class converts the access code to a textual representation and can also
# parse that representation.
class AccessCode

  # Create an AccessCode object from existing key material
  #
  # payload  -  a binary string containing the access code's key
  def initialize payload
    @payload = payload
  end

  def self.from_channel channel_id, channel_secret
    self.new channel_id + channel_secret
  end

  # Parse an access code in ASCII format.
  # These are BASE32 encoded.
  def self.parse str
    raise "Wrong length, should be 40 characters, not #{str.size} characters" unless str.size == 40

    str.upcase!

    # remove check digit
    str = LuhnCheck.verify str

    raise "Fails Luhn_mod_N check" unless str

    self.new str
  end

  # Get base32 representation of the access code, for sharing with other
  # people.
  def to_s
    Base32.encode(LuhnCheck.generate(@payload))
  end
end
