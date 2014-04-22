class GnuTLS::Server < GnuTLS::Session
  def initialize socket, username, password
    ptr = GnuTLS.init GnuTLS::SERVER
    super ptr, :server
    self.creds = [username, password]
    self.socket = socket
  end
end
