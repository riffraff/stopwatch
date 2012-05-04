module Stopwatch
  class Log
    @@query_count = 0
    @@sub_query_count = 0
    @@events = []
    @@sub_queries = []

    cattr_accessor :event
    cattr_accessor :events
    cattr_accessor :query_count
    cattr_accessor :sub_queries
    @@controller_start = nil
    cattr_accessor :controller_start

    def self.query_count
      @@query_count
    end

    def self.sub_query_count
      @@sub_query_count
    end

    def self.reset_query_count
      @@query_count = 0
    end

    def self.reset_sub_queries
      @@sub_queries = []
    end

    def self.reset_sub_query_count
      @@sub_query_count = 0
    end

    def self.increment_query_count
      @@query_count += 1
    end

    def self.increment_sub_query_count
      @@sub_query_count += 1
    end

    def self.add_sub_query payload
      @@sub_queries << payload
    end

    def self.reset_events
      @@events = []
    end
  end
end
