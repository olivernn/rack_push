module Rack
  module Push
    class Request < Rack::Request
      include Rack::Utils

      attr_reader :env

      def initialize(env)
        @env = env
        super(env)
      end

      def channel
        path_info.split('/').last
      end

      [:event, :socket_id].each do |param|
        define_method param do
          str = ""
          query_string.split(query_string_seperator).each do |pair|
            str = pair.gsub("#{param}=", "") if pair.match("#{param}=")
          end
          str
        end
      end

      def event_data
        self.body.rewind
        self.body.read
      end

      def well_formed?
        !event.empty? && !socket_id.empty? && !channel.empty? && !event_data.empty?
      end

      private

      def query_string_seperator
        query_string.match(";") ? ";" : "&"
      end
    end
  end
end