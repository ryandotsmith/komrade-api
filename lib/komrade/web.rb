require 'json'
require 'sinatra/base'
require 'rack/handler/mongrel'
require 'rack/ssl-enforcer'

require 'komrade/conf'
require 'komrade/utils'
require 'komrade/queue'
require 'komrade/stats_raw'
require 'komrade/stats_min'
require 'komrade/stats_hour'
require 'komrade/errors'
require 'komrade/heroku'
require 'komrade/failed_job'

module KomradeApi
  class Web < Sinatra::Base
    use Rack::SslEnforcer unless Conf.development_mode?
    use Rack::Session::Cookie, secret: ENV['SSO_SALT']
    set :public_folder, "./public"
    set :views, "./templates"

    # Instrumentation
    def self.route(verb, action, *)
      condition {@instrument_action = [verb, action].join(" ")}
      super
    end
    before {@start_request = Time.now}
    after {log(measure: @instrument_action, val: (Time.now - @start_request))}

    #Always include server time in response
    before do
      t = KomradeApi.pg["select now()"].get.to_s
      headers("X_SERVER_TIME" => t)
    end

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

    if Conf.development_mode?
      module Heroku
        def self.get_app(*args)
          {"name" => "hello-world"}
        end
      end
      before do
        session[:email] = 'dev@komrade.io'
        session[:queue_id] = ENV["QUEUE_TOKEN"] || Queue.first[:token]
      end
    end

    get "/admin" do
      protect_admin
      @customers = Queue.all.map do |q|
        {
          app: Heroku.get_app(q[:callback_url]),
          queue: q
        }
      end.reject {|h| h[:app].nil?}
      erb(:admin)
    end

    # SSO Index.
    get "/" do
      halt 403, 'not logged in' unless session[:email]
      @queue = Queue.find(session[:queue_id])
      @app = Heroku.get_app(@queue[:callback_url])
      erb(:index)
    end

    get '/summary' do
      halt 403, 'not logged in' unless session[:email]
      @queue = Queue.find(session[:queue_id])
      @app = Heroku.get_app(@queue[:callback_url])
      status(200)
      body(JSON.dump({app_name: @app['name'], queue_length: @queue[:length]}))
    end

    get '/metrics' do
      halt 403, 'not logged in' unless session[:email]
      @queue = Queue.find(session[:queue_id])
      res = case params[:resolution]
      when 'hour'
        StatsMin.aggregate(@queue[:token])
      when 'day'
        StatsHour.aggregate(@queue[:token])
      when 'second'
        StatsRaw.aggregate(@queue[:token], 5)
      else
        status(404)
        body(JSON.dump({msg: "Resolution not found."}))
        return
      end
      status(200)
      body(JSON.dump(res))
    end

    get '/failed-jobs' do
      halt 403, 'not logged in' unless session[:email]
      res = FailedJob.aggregate(session[:queue_id], 20, 0, params[:resolution])
      status(200)
      body(JSON.dump(res))
    end

    get '/jobs/:jid/failed-jobs' do
      halt 403, 'not logged in' unless session[:email]
      res = FailedJob.by_job(params[:jid])
      status(200)
      body(JSON.dump(res))
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
    def log(data, &blk); self.class.log(data, &blk);end


  end
end
