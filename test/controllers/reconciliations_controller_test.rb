require "test_helper"

class ReconciliationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get reconciliations_new_url
    assert_response :success
  end

  test "should get analyze" do
    get reconciliations_analyze_url
    assert_response :success
  end
end
