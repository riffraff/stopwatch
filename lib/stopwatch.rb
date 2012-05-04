require 'load_speed'
require 'stopwatch/log'
require 'stopwatch/event'

module Stopwatch
  
 
  # there is no event signaling the start of view rendering code, AFAICT
  module ControllerRenderHook
    def render *args
      ActiveSupport::Notifications.instrument("start_rendering.action_controller", 
                                              {:identifier=>'controller', :start=>Stopwatch::Log.controller_start})
      super
    end
  end
  ActionController::Base.send :include, ControllerRenderHook

  class Railtie < Rails::Railtie
    initializer "newplugin.initialize" do |app|
      app.config.middleware.use "Rack::LoadSpeed"

      # Start processing
      ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |*args|
        Stopwatch::Log.reset_query_count
        Stopwatch::Log.reset_sub_query_count
        Stopwatch::Log.reset_sub_queries
        Stopwatch::Log.reset_events
        Stopwatch::Log.controller_start = Time.now
      end

      # Every query
      ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
        if payload[:name] !~ /^CACHE| Indexes$/
          event = ActiveSupport::Notifications::Event.new(name, start, finish, id, payload)
          Stopwatch::Log.increment_query_count
          Stopwatch::Log.add_sub_query payload
        end
      end

      # Every partial render
      ActiveSupport::Notifications.subscribe(/render/) do |name, start, finish, id, payload|
        if name == 'start_rendering.action_controller'
          event = ActiveSupport::Notifications::Event.new(name, payload[:start], finish, id, payload)
        else
          event = ActiveSupport::Notifications::Event.new(name, start, finish, id, payload)
        end
        stopwatch_event = Stopwatch::Event.new(event)
        stopwatch_event.queries = Stopwatch::Log.sub_queries
        Stopwatch::Log.events << stopwatch_event
        Stopwatch::Log.reset_sub_queries
      end

      # End of processing
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
        Stopwatch::Log.event = ActiveSupport::Notifications::Event.new(*args)
      end
    end
  end
end
