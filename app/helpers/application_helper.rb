module ApplicationHelper
  def weight_chart_points(weight_logs, width: 600, height: 180, padding: 16)
    logs = weight_logs.sort_by(&:logged_at)
    return "" if logs.empty?

    weights = logs.map { |log| log.weight_kg.to_f }
    minimum, maximum = weights.minmax
    range = maximum - minimum
    x_step = logs.one? ? 0 : (width - padding * 2).fdiv(logs.size - 1)

    weights.each_with_index.map do |weight, index|
      x = logs.one? ? width / 2.0 : padding + index * x_step
      y = range.zero? ? height / 2.0 : padding + (maximum - weight).fdiv(range) * (height - padding * 2)
      "#{x.round(2)},#{y.round(2)}"
    end.join(" ")
  end
end
