require 'uri'
require 'komrade/conf'
require 'komrade/http_helpers'

module Komrade
  module Heroku
    extend self

    def get_app(url)
      uri = URI.parse(url)
      uri.user = Conf.heroku_username
      uri.password = Conf.heroku_password
      HttpHelpers.get(uri)
    end

  end
end
