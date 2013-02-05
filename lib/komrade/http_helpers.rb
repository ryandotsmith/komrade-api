require 'net/http'
require 'json'
require 'uri'

module Komrade
  module HttpHelpers
    extend self
    MAX_RETRY = 3

    def get(uri)
      make_request(uri, Net::HTTP::Get.new(uri.path))
    end

    def put(uri, body=nil)
      make_request(uri, Net::HTTP::Put.new(uri.path), body)
    end

    def post(uri, body=nil)
      make_request(uri, Net::HTTP::Post.new(uri.path), body)
    end


    def make_request(uri, req, body=nil)
      req.basic_auth(uri.user, uri.password)
      if body
        req.content_type = 'application/json'
        req.body = JSON.dump(body)
      end
      attempts = 0
      while attempts < MAX_RETRY
        begin
          resp = nil
          resp = http(uri).request(req)
          if (Integer(resp.code) / 100) == 2
            begin
              return JSON.parse(resp.body)
            rescue JSON::ParserError
              return resp.body
            end
          end
        rescue Net::HTTPError => e
          next
        ensure
          attempts += 1
        end
      end
    end

    def http(uri)
      Net::HTTP.new(uri.host, uri.port).tap do |h|
        if uri.scheme == 'https'
          h.use_ssl = true
          h.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
    end

  end
end
