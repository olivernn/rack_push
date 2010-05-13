require 'rubygems'
require 'rack'
require 'pusher'
require 'rack_push'

use Rack::Push::App, :key => '8ebcdcaa1f1cee3ff93e', :app_id => '19', :secret => '05f9c3f0185f6045147a'

run lambda { |env| [200, {'Content-Length' => '10', 'Content-Type' => 'text/plain'}, ["NOT PUSHER"]] }