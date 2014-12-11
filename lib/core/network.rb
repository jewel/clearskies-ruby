# Manage connections with peers.  See "Connection" for more information.

require 'socket'
require_relative 'simple_thread'
require_relative 'broadcaster'
require_relative 'tracker_client'
require_relative 'unauthenticated_connection'
require_relative 'id_mapper'
require_relative 'upnp'
require_relative 'connection_manager'
require_relative 'shared_udp_socket'
require_relative 'stun_client'
require_relative 'utp_socket'

module Network
  # Start all network-related pieces.  This spawns several background threads.
  def self.start
    @connections = {}

    @server = UnlockingTCPServer.new '0.0.0.0', 0

    SimpleThread.new('network') do
      listen
    end
  end

  private
  # Listen for incoming clearskies connections.
  def self.listen
    loop do
      client = @server.accept
      start_connection client
    end
  end

  # Current listening port.  This will be different than Conf.listen_port if
  # Conf.listen_port is set to 0.
  def self.listen_port
    @server.local_address.ip_port
  end

  # Start a connection, regardless of source.
  def self.start_connection *args
    connection = UnauthenticatedConnection.new *args

    ConnectionManager.connecting connection

    connection.on_authenticated do |connection|
      ConnectionManager.connected connection
    end

    connection.start

    nil
  end
end
