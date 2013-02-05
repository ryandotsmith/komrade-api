require 'json'
require 'sinatra/base'
require 'rack/handler/mongrel'
require 'rack/ssl-enforcer'


require 'komrade/conf'
require 'komrade/utils'
require 'komrade/queue'
require 'komrade/stats'
require 'komrade/errors'
require 'komrade/heroku'

module Komrade
  class Web < Sinatra::Base
    use Rack::SslEnforcer
    use Rack::Session::Cookie, secret: ENV['SSO_SALT']
    set :public_folder, "./public"
    set :views, "./templates"

    helpers do
      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials &&
        @auth.credentials == [ENV['HEROKU_USERNAME'], ENV['HEROKU_PASSWORD']]
      end

      def protect_admin
        unless authorized_admin?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized_admin?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials &&
        @auth.credentials == [Conf.admin_username, Conf.admin_password]
      end
    end

    get "/admin" do
      protect_admin
      @customers = Queue.all.map do |q|
        {
          app: Heroku.get_app(q[:callback_url]),
          queue: q,
          stats: Stats.all(q[:token])
        }
      end.reject {|h| h[:app].nil?}
      erb(:admin)
    end

    # SSO Index.
    get "/" do
      halt 403, 'not logged in' unless session[:email]
      @queue = Queue.find(session[:queue_id])
      @stats = Stats.all(@queue[:token])
      @errors = Errors.get(@queue[:token])
      @app = Heroku.get_app(@queue[:callback_url])
      erb(:index)
    end

    post '/sso/login' do
      pre_token = params[:id] + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
      token = Digest::SHA1.hexdigest(pre_token).to_s
      halt 403 if token != params[:token]
      halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i
      q = Queue.find(params[:id])
      halt 404 if q.nil?
      session[:queue_id] = q[:token]
      session[:email] = params['email']
      redirect '/'
    end

    # Provision
    post '/heroku/resources' do
      protected!
      req = JSON.parse(request.body.read)
      if queue = Queue.create(req)
        [201, JSON.dump(queue)]
      else
        [400, JSON.dump(msg: "Unable to provision queue.")]
      end
    end

    # Deprovision
    delete '/heroku/resources/:id' do
      protected!
      if Queue.delete(params[:id])
        [200, JSON.dump(msg: "OK")]
      else
        [400, JSON.dump(msg: "Unable to delete queue.")]
      end
    end

    # Plan change
    put '/heroku/resources/:id' do
      protected!
      req = JSON.parse(request.body.read)
      if Queue.change_plan(params[:id], req['plan'])
        [200, JSON.dump(msg: "Plan changed.")]
      else
        [400, JSON.dump(msg: "Unable to change plan.")]
      end
    end

    def self.start
      log(fn: "start", at: "build")
      @server = Mongrel::HttpServer.new("0.0.0.0", Conf.port)
      @server.register("/", Rack::Handler::Mongrel.new(Web.new))
      log(fn: "start", at: "install_trap")
      ["TERM", "INT"].each do |s|
        Signal.trap(s) do
          log(fn: "trap", signal: s)
          @server.stop(true)
          log(fn: "trap", signal: s, at: "exit", status: 0)
          Kernel.exit!(0)
        end
      end
      log(fn: "start", at: "run", port: Conf.port)
      @server.run.join
    end

    def self.log(data, &blk)
      Utils.log({ns: "web"}.merge(data), &blk)
    end

  end
end
