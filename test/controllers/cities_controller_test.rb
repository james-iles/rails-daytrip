require "test_helper"

class CitiesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get cities_create_url
    assert_response :success
  end

  test "should get show" do
    get cities_show_url
    assert_response :success
  end
end
