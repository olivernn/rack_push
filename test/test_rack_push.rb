require 'helper'

class TestRackPush < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    TestRackPush.class_eval { def app; using_default_params; end }
    Pusher.key = 'pusher_key'
    Pusher.app_id = 'app_id'
    Pusher.secret = 'secret'
  end

  def using_default_params
    # default url for Rack::Push is '/pusher'
    Rack::Push::App.new lambda { |env|
      [200, {'Content-Length' => '10', 'Content-Type' => 'text/plain'}, ["NOT PUSHER"]]
    }, :key => 'pusher_key', :app_id => 'app_id', :secret => 'secret'
  end

  def using_custom_params
    Rack::Push::App.new lambda { |env|
      [200, {'Content-Length' => '10', 'Content-Type' => 'text/plain'}, ["NOT PUSHER"]]
    }, :key => 'pusher_key', :app_id => 'app_id', :secret => 'secret', :path => '/customized/path', :method => :put
  end

  test "bypassing Rack::Push" do
    Pusher['my_channel'].expects(:trigger).never
    get '/not_pusher'
    assert last_response.ok?
    assert_equal "NOT PUSHER", last_response.body
  end

  test "sending a request to pusher" do
    mock_channel = mock('channel')
    mock_channel.stubs(:trigger)
    Pusher.stubs(:[]).returns(mock_channel)
    Pusher['my_channel'].expects(:trigger).with('my_event', '{"title":"pushing"}', '123')
    post '/pusher/my_channel?event=my_event&socket_id=123', '{"title":"pushing"}'
    assert last_response.ok?
    assert_not_equal "NOT PUSHER", last_response.body
  end

  test "ignoring wrong request methods" do
    Pusher['my_channel'].expects(:trigger).never
    put '/pusher/my_channel?event=my_event&socket_id=123', '{"title":"pushing"}'
    assert last_response.ok?
    assert_equal "NOT PUSHER", last_response.body
  end

  test "handling missing parameters" do
    Pusher['my_channel'].expects(:trigger).never
    post '/pusher/my_channel?event=my_event', '{"title":"pushing"}'
    assert_equal 412, last_response.status
  end

  test "trying to push no data" do
    Pusher['my_channel'].expects(:trigger).never
    post '/pusher/my_channel?event=my_event&socket_id=123'
    assert_equal 412, last_response.status
  end

  test "bypassing when using custom params" do
    TestRackPush.class_eval { def app; using_custom_params; end }
    Pusher['my_channel'].expects(:trigger).never
    get '/not_pusher'
    assert last_response.ok?
    assert_equal "NOT PUSHER", last_response.body
  end

  test "sending a request to pusher when using custom params" do
    TestRackPush.class_eval { def app; using_custom_params; end }
    mock_channel = mock('channel')
    mock_channel.stubs(:trigger)
    Pusher.stubs(:[]).returns(mock_channel)
    Pusher['my_channel'].expects(:trigger).with('my_event', '{"title":"pushing"}', '123')
    put '/customized/path/my_channel?event=my_event&socket_id=123', '{"title":"pushing"}'
    assert last_response.ok?
    assert_not_equal "NOT PUSHER", last_response.body
  end
end
