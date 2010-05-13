module Rack
  module Push
    class App
      def initialize app, options
        @app = app
        @path = options[:path] || '/pusher'
        @method = options[:method] || :post
        Pusher.key = options[:key]
        Pusher.app_id = options[:app_id]
        Pusher.secret = options[:secret]
      end

      def call(env)
        request = Push::Request.new(env)
        if push_this request
          if request.well_formed?
            Pusher[request.channel].trigger(
              request.event,
              request.event_data,
              request.socket_id
            )
            [200, {"Content-Type" => "text/plain", "Content-Length" => "0"}, [""]]
          else
            [412, {"Content-Type" => "text/plain", "Content-Length" => "0"}, [""]]
          end
        else
          @app.call(env)
        end
      end

      private

      def push_this request
        (request.request_method.downcase.to_sym == @method) && (!!request.path_info.match(%r{^#{@path}/[\w-]*$}))
      end
    end
  end
end