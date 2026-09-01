require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "builds deterministic weight trend points" do
    points = weight_chart_points([ weight_logs(:pepper_latest), weight_logs(:pepper_older) ])
    assert_equal "16.0,164.0 584.0,16.0", points
  end
end
