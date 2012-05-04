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
      events = <<-HEADER
 <table id='performance_table'>
  <tr>
    <td colspan="55%">event</td>
    <td colspan="15%">time (ms)</td>
    <td colspan="15%">queries</td>
    <td colspan="15%">actions </td>
  </tr>
 HEADER
      Stopwatch::Log.events.each_with_index do |event, idx|
        indexed_unique_id = "evt-#{unique_page_id}-#{idx}"
        queries = event.queries.map {|p| "<li>#{p[:sql]}</li>"}.join("\n")
        query_line = queries == '' ? '' : %{<a href="##{indexed_unique_id}">show</a>/<a href="#">hide</a>}
        events << <<-HTML
<tr id="#{indexed_unique_id}" >
  <td colspan="55%">#{event.template}   </td>
  <td colspan="15%">#{event.duration}   </td> 
  <td colspan="15%">#{event.query_count}</td> 
  <td colspan="15%">#{query_line}       </td>
</tr>
<tr class="queries">
  <td colspan="100%">
    <ol>
      #{queries}
    </ol>
  </td>
</tr>
HTML
      end
      event = Stopwatch::Log.event
      events << <<-HTML
<tr>
  <td colspan="55%">#{event.payload[:path]}</td>
  <td colspan="15%">#{event.duration}</td>
  <td colspan="15%">#{Stopwatch::Log.query_count}</td>
  <td colspan="15%"></td>
</tr>"
HTML
      events << "</table>"

      html = <<-EOF
<style>
  #performance_code {
    z-index: 1000;
    position: absolute;
    top: 0;
    right: 0;
    height: 25px;

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
    width: 100%;
    table-layout: fixed;
  }

  table#performance_table td {
    padding-right: 15px;
  }
  
  table#performance_table tr.queries {
    display: none;
    font-size: smaller;
  }
  table#performance_table tr.queries li {
    width: 500px;
    text-align:left;
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
