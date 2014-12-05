require_relative 'access_code'

module Core
  def self.init(errors_callback)
    @errors_callback = errors_callback
    nil
  end

  def self.start
  end

  def self.stop
  end

  def self.create_club
    #club = Club.new
    #@clubs[club.peerid] = club
    #club.peerid
  end

  def self.generate_access_code(peerid, level)
    ac = AccessCode.create
    # TODO: @clubs[peerid].add_access_code(ac)

    ac.to_s
  end

  def self.join_club(access_code)
    # duping in case access_code was passed in from ARGV
    ac = AccessCode.parse access_code.dup
    return "MY_PEERID"
  end

  def self.list_peers(peerid)
    #@clubs[peerid]
    []
  end


  ### The following are generally useful for extensions and not 
  ### usually needed otherwise.

  # Register a message handler for a given type.
  #
  # The type may be a glob, like '.com.testing.*' or
  # you may register a seperate callback for each, 
  # like '.com.testing.start', '.com.testing.end'
  def self.register_type(type_glob, message_handler)
    #TODO globs are not yet supported
    #@type_handlers = 
  end
end
