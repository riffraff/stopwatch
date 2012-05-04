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
      events = "<table id='performance_table'><tr><th></th><th>duration (ms)</th><th>queries</th></tr>"
      Stopwatch::Log.events.each_with_index do |event, idx|
        queries = event.queries.map {|p| "<li>#{p[:sql]}</li>"}.join("\n")
        query_line = queries == '' ? '' : %{<a href="#evt-#{idx}">show</a>/<a href="#">hide</a>}
        events << <<-HTML
<tr id="evt-#{idx}">
  <td>#{event.template}</td> 
  <td>#{event.duration}</td> 
  <td>#{event.query_count}</td> 
  <td>#{query_line}</td>
</tr>
<tr class="queries">
  <td colspan="4" align="right">
    <ol>
      #{queries}
    </ol>
  </td>
</tr>
HTML
      end
      event = Stopwatch::Log.event
      events << "<tr><td>#{event.payload[:path]}</td><td>#{event.duration}</td><td>#{Stopwatch::Log.query_count}</td></tr>"
      events << "</table>"

      html = <<-EOF
<style>
  #performance_code {
    z-index: 1000;
    position: absolute;
    top: 0;
    right: 0;
    height: auto;

    width: 140px;
    overflow: hidden;
    background-color: #DE7A93;
    color: white;
    padding: 0 10px 0 10px;
    line-height: 20pt;
    font-family: "menlo";
    font-size: 10pt;
    text-align: right;
  }

  #performance_code:hover {
    height: auto;
    width: 600px;
    padding-bottom: 10px;
  }

  table#performance_table {
  }

  table#performance_table td {
    padding-right: 15px;
  }
  
  table#performance_table tr.queries {
    display: none;
    font-size: smaller;
  }
  table#performance_table tr:target + .queries {
    display:block !important;
  }
</style>
<div id="performance_code">
  <strong>#{Stopwatch::Log.event.duration.to_i}</strong> ms
  <strong>#{Stopwatch::Log.query_count}</strong> queries
  #{events}
</div>
EOF
      html
    end
  end
end
