class GnuTLS::Socket < GnuTLS::Session
  def initialize socket, username, password
    ptr = GnuTLS.init GnuTLS::CLIENT
    super ptr, :client
    self.creds = [username, password]
    self.socket = socket
  end
end
