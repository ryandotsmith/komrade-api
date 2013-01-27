require 'uri'
require 'conf'
require 'http_helpers'

module App
  extend self

  def get(url)
    uri = URI.parse(url)
    uri.user = Conf.heroku_username
    uri.password = Conf.heroku_password
    HttpHelpers.get(uri)
  end

end
