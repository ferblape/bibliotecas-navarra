# Fly Proxy sets Fly-Client-IP to the visitor's address. X-Forwarded-For ends
# with the app's own public IP instead, which ActionDispatch::RemoteIp would
# take as the client of every request.
class FlyClientIp
  def initialize(app)
    @app = app
  end

  def call(env)
    if (client_ip = env["HTTP_FLY_CLIENT_IP"].presence)
      env["action_dispatch.remote_ip"] = client_ip
    end

    @app.call(env)
  end
end
