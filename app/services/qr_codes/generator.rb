module QrCodes
  class Generator
    def initialize(url)
      @url = url
    end

    def svg
      RQRCode::QRCode.new(url).as_svg(
        color: "1d2a25",
        fill: "ffffff",
        module_size: 12,
        offset: 4,
        shape_rendering: "crispEdges",
        use_path: true,
        viewbox: true
      )
    end

    private
      attr_reader :url
  end
end
