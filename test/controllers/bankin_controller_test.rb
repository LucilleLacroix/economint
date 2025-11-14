require "test_helper"

class BankinControllerTest < ActionDispatch::IntegrationTest
  test "should get connect" do
    get bankin_connect_url
    assert_response :success
  end

  test "should get callback" do
    get bankin_callback_url
    assert_response :success
  end
end
