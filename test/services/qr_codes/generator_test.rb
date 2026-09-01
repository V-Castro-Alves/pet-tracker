require "test_helper"

class QrCodes::GeneratorTest < ActiveSupport::TestCase
  test "generates an SVG QR code" do
    svg = QrCodes::Generator.new("https://example.test/meal_log/token").svg

    assert_includes svg, "<svg"
    assert_includes svg, "viewBox"
    assert_includes svg, "<path"
  end
end
