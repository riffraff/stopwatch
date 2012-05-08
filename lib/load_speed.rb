module Rack
  class LoadSpeed

    def initialize(app)
      @app = app
    end

    def call(env)
      env.delete("HTTP_IF_NONE_MATCH")
      status, headers, response = @app.call(env)

      if status == 200 && headers["Content-Type"] =~ /text\/html|application\/xhtml\+xml/
        body = ""
        response.each {|part| body << part}
        index = body.rindex("</body>")
        if index
          body.insert(index, performance_code)
          headers["Content-Length"] = body.length.to_s
          response = [body]
        end
      end

      [status, headers, response]
    end

  protected

    def performance_code
      # to avoid reopening on page reload
      unique_page_id = Time.now.to_i.to_s

      current_log = Stopwatch.current_log

      # items is soemthing like
      # [[first col, second col, third col, fourth col, payload data, unique id]]
      items = []
      items << ['event', 'time (ms)', 'queries', 'actions']
      current_log.events.each_with_index do |event, idx|
        indexed_unique_id = "evt-#{unique_page_id}-#{idx}"
        items << [event.template, event.duration, event.query_count, nil, event.queries, indexed_unique_id]
      end
      event = current_log.event
      items << [event.payload[:path], event.duration, current_log.query_count]

      include ERB::Util
      ERB.new(Stopwatch.template).result(binding)
    end
  end
end

