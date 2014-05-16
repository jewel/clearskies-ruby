# FFI interface for GNUTLS.  At the time of writing, OpenSSL does not implement
# the DHE-PSK TLS modes, which are necessary for clearskies.
#
# See https://defuse.ca/gnutls-psk-client-server-example.htm

require 'ffi'
require 'socket'

# Open the module early so that subclasses can be created
module GnuTLS; end

require_relative 'gnutls/session'
require_relative 'gnutls/server'
require_relative 'gnutls/socket'
require_relative 'gnutls/error'

module GnuTLS
  # Connect to malloc.
  module LibC
    extend FFI::Library
    ffi_lib FFI::Library::LIBC
    attach_function :malloc, [:size_t], :pointer
  end

  extend FFI::Library
  loaded = false
  %w{/usr/local/lib/libgnutls.so gnutls gnutls.so.26 gnutls.so.28}.each do |lib|
    begin
      ffi_lib lib
      loaded = true
      break
    rescue 
    end
  end
  raise "cannot load gnutls" unless loaded

  ffi_libraries.each do |lib|
    $stderr.puts lib.name
  end


def write_string str
  # FIXME check for malloc failure
  self[:data] = LibC.malloc str.bytesize
  self[:data].write_bytes str, 0, str.bytesize
  self[:size] = s.bytesize
end
  # structs
  class Datum < FFI::Struct
    layout :data, :pointer,
           :size, :uint
def copy other
  self[:data] = other[:data]
  self[:size] = other[:size]
end

  end

  #FIXME: figure out which size is the best to use (4096, 3072, 2048, 1536, or 1024)
  attach_variable :srp_2048_group_prime, :gnutls_srp_2048_group_prime, Datum
  attach_variable :srp_2048_group_generator, :gnutls_srp_2048_group_generator, Datum


  # typedefs
  typedef :pointer, :session
  typedef :pointer, :creds
  typedef :pointer, :creds

  # types
  enum :credentials_type, [:crd_certificate, 1,
                           :crd_anon,
                           :crd_srp,
                           :crd_psk,
                           :crd_ia]
  enum :psk_key_type, [
    :psk_key_raw,
    :psk_key_hex
  ]

  enum :close_request_type, [:shut_rdrw, 0,
                        :shut_rw]

  # callbacks
  callback :log_function, [:int, :string], :void
  callback :push_function, [:pointer, :pointer, :size_t], :size_t
  callback :pull_function, [:pointer, :pointer, :size_t], :size_t
  callback :psk_creds_function, [:session, :string, :pointer], :int
  callback :srp_server_credentials_function, [:pointer,:string,:pointer,:pointer,:pointer,:pointer], :int

  def self.tls_function name, *args
    attach_function name, :"gnutls_#{name}", *args
  end

  # global functions
  tls_function :global_init, [], :void
  tls_function :global_set_log_level, [ :int ], :void
  tls_function :global_set_log_function, [ :log_function ], :void

  tls_function :check_version, [ :string ], :string

  # functions
  attach_function :gnutls_init, [:pointer, :int], :int

  tls_function :bye, [:session, :close_request_type], :int
  tls_function :deinit, [:session], :void
  tls_function :error_is_fatal, [:int], :int
  tls_function :priority_set_direct, [:session, :string, :pointer], :int
  tls_function :credentials_set, [:session, :credentials_type, :creds], :int
  tls_function :psk_allocate_client_credentials, [:pointer], :int
  tls_function :psk_allocate_server_credentials, [:pointer], :int
  tls_function :psk_set_client_credentials, [:creds, :string, Datum, :psk_key_type ], :int
  tls_function :psk_set_server_credentials_function, [:creds, :psk_creds_function], :int
  tls_function :srp_allocate_server_credentials, [:pointer], :int
  tls_function :srp_allocate_client_credentials, [:pointer], :int
  tls_function :srp_set_client_credentials, [:creds, :string, :string], :int
  tls_function :srp_set_server_credentials_function, [:creds, :srp_server_credentials_function], :void

  tls_function :srp_verifier,[:string, :string,:pointer, :pointer, :pointer, :pointer], :int

  tls_function :transport_set_push_function, [:session, :push_function], :void
  tls_function :transport_set_pull_function, [:session, :pull_function], :void


  begin
    tls_function :transport_set_int, [:session, :int], :void
  rescue FFI::NotFoundError
  end

  tls_function :handshake, [:session], :int
  tls_function :record_recv, [:session, :pointer, :size_t], :int
  tls_function :record_send, [:session, :pointer, :size_t], :int
  # tls_function :handshake_set_timeout, [:pointer, :int], :void

  tls_function :global_set_log_level, [:int], :void
  tls_function :global_set_log_function, [:log_function], :void
  tls_function :strerror, [:int], :string

  SERVER = 1
  CLIENT = 2

  # Create a server or client, and return the pointer to the session struct
  def self.init type
    GnuTLS.global_init unless @global_initted
    @global_initted = true

    FFI::MemoryPointer.new :pointer do |ptr|
      gnutls_init(ptr, type)
      return ptr.read_pointer
    end
  end

  # Turn on GnuTLS logging
  def self.enable_logging
    @logging_function = Proc.new { |lvl,msg| puts "#{Process.ppid} #{lvl} #{msg}" }
    GnuTLS.global_set_log_function @logging_function
    GnuTLS.global_set_log_level 99
  end
end
