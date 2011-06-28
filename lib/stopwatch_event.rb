class StopwatchEvent
  attr_accessor :query_count

  def initialize(event)
    @event = event
  end

  def template
    @event.payload[:identifier].gsub(/.*\/app\/views\//, "")
  end

  def duration
    @event.duration.round(2)
  end
end
