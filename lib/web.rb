require 'json'
require 'sinatra/base'
require 'rack/handler/mongrel'
require 'heroku/nav'
require 'conf'
require 'utils'
require 'kqueue'

class Web < Sinatra::Base
  use Rack::Session::Cookie, secret: ENV['SSO_SALT']

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

    def sso
      pre_token = params[:id] + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
      token = Digest::SHA1.hexdigest(pre_token).to_s
      halt 403 if token != params[:token]
      halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i

      halt 404 unless session[:resource] = KQueue.exists?(params[:id])

      response.set_cookie('heroku-nav-data', value: params['nav-data'])
      session[:heroku_sso] = params['nav-data']
      session[:email]      = params[:email]

      redirect '/'
    end
  end

  # sso landing page
  get "/" do
    halt 403, 'not logged in' unless session[:heroku_sso]
    #response.set_cookie('heroku-nav-data', value: session[:heroku_sso])
    @resource = session[:resource]
    @email    = session[:email]
    haml :index
  end

  # SSO sign in.
  get "/heroku/resources/:id" do
    sso
  end

  post '/sso/login' do
    sso
  end

  # Provision
  post '/heroku/resources' do
    protected!
    req = JSON.parse(request.body.read)
    if queue = KQueue.create(req)
      [201, JSON.dump(queue)]
    else
      [400, JSON.dump(msg: "Unable to provision queue.")]
    end
  end

  # Deprovision
  delete '/heroku/resources/:id' do
    protected!
    if KQueue.delete(params[:id])
      [200, JSON.dump(msg: "OK")]
    else
      [400, JSON.dump(msg: "Unable to delete queue.")]
    end
  end

  # Plan change
  put '/heroku/resources/:id' do
    protected!
    req = JSON.parse(request.body.read)
    if KQueue.change_plan(params[:id], req['plan'])
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
