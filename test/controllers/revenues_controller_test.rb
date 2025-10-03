require "test_helper"

class RevenuesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get revenues_index_url
    assert_response :success
  end

  test "should get show" do
    get revenues_show_url
    assert_response :success
  end

  test "should get new" do
    get revenues_new_url
    assert_response :success
  end

  test "should get edit" do
    get revenues_edit_url
    assert_response :success
  end
end
