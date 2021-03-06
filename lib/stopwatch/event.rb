module Stopwatch
  class Event
    attr_accessor :queries

    def initialize(event)
      @event = event
    end

    def query_count
      queries.size
    end

    def template
      if @event.payload[:virtual_path]
        @event.payload[:virtual_path]
      else
        @event.payload[:identifier].gsub(/.*\/app\/views\//, "")
      end
    end

    def duration
      @event.duration.round(2)
    end
  end
end
