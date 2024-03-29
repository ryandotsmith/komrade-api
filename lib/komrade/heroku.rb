require 'uri'
require 'komrade/conf'
require 'komrade/http_helpers'

module KomradeApi
  module Heroku
    extend self

    def get_app(url)
      return {name: 'dev-app'} if Conf.development_mode?
      uri = URI.parse(url)
      uri.user = Conf.heroku_username
      uri.password = Conf.heroku_password
      HttpHelpers.get(uri)
    end

    def update_config(queue)
      uri = URI.parse(queue[:callback_url])
      uri.user = Conf.heroku_username
      uri.password = Conf.heroku_password
      HttpHelpers.put(uri, config: {'KOMRADE_URL' => Queue.queue_url(queue)})
    end

  end
end
