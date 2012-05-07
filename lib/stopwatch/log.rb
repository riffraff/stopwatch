module Stopwatch
  class Log
    def initialize 
      @query_count = 0
      @sub_query_count = 0
      @events = []
      @sub_queries = []
    end

    attr_accessor :event, 
                  :events, 
                  :query_count, 
                  :sub_queries, 
                  :controller_start

    def query_count
      @query_count
    end


    def reset_query_count
      @query_count = 0
    end

    def reset_sub_queries
      @sub_queries = []
    end

    def reset_sub_query_count
      @sub_query_count = 0
    end

    def increment_query_count
      @query_count += 1
    end

    def increment_sub_query_count
      @sub_query_count += 1
    end

    def add_sub_query payload
      @sub_queries << payload
    end

    def reset_events
      @events = []
    end
  end
end
