require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get budgets_index_url
    assert_response :success
  end

  test "should get new" do
    get budgets_new_url
    assert_response :success
  end

  test "should get create" do
    get budgets_create_url
    assert_response :success
  end
end
