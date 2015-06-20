require_relative '../../test/channel'

module Core
  def self.init(errors_callback)
    @errors_callback = errors_callback
    @type_handlers = {} # must be initailized before calling register_type
    @channels = {}
    @thread = nil

    # TODO register the core message handlers
    self.register_type("core.greeting", "some handler")
    # ... etc ...
    nil
  end

  def self.start
    @thread = Thread.new do
      loop do
        @channels.each do |k,chan|
          m = chan.read_message
          if m
            # TODO: invoke message handler
            puts "Got message: " + m
          end
        end
        # TODO: upgrade to using select instead of spinning
        sleep 0.05
      end
    end
    @thread.abort_on_exception = true
  end

  def self.stop
    @thread.kill
    @thread = nil
  end

  def self.create_channel
    channel = Channel.new "sample_chat"
    @channels[channel.channel_id] = channel
    channel.channel_id
  end

  def self.get_access_code(channel_id)
    @channels[channel_id].access_code
  end

  def self.join_channel(access_code)
    # duping in case access_code was passed in from ARGV
    c = Channel.join_channel access_code.dup
    @channels[c.channel_id] = c
    c.channel_id
  end

  def self.list_peers(channel_id)
    @channels[channel_id].list_peers
  end

  def self.send_message(channel_id, message)
    @channels[channel_id].send_message message
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
    $stderr.puts "Warning: overrode existing handler for #{type_glob}" if @type_handlers.has_key? type_glob
    @type_handlers[type_glob] = message_handler
  end
end
