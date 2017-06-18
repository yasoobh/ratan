require 'test_helper'

class ExpenseControllerTest < ActionDispatch::IntegrationTest
  test "should get get_expenses_by_month" do
    get expense_get_expenses_by_month_url
    assert_response :success
  end

  test "should get get_expenses_for_services" do
    get expense_get_expenses_for_services_url
    assert_response :success
  end

  test "should get get_todays_expenses" do
    get expense_get_todays_expenses_url
    assert_response :success
  end

  test "should get upload_expenses" do
    get expense_upload_expenses_url
    assert_response :success
  end

end
