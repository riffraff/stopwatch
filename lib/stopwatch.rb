require 'load_speed'
require 'stopwatch/log'
require 'stopwatch/event'

module Stopwatch
  
  LOG_THREAD_LOCAL_NAME = name+'_'+'_current_log'
  def self.current_log
    Thread.current[LOG_THREAD_LOCAL_NAME] ||= Stopwatch::Log.new
  end

  # there is no event signaling the start of view rendering code, AFAICT
  module ControllerRenderHook
    def render *args
      ActiveSupport::Notifications.instrument("start_rendering.action_controller", 
                                              {:identifier=>'controller', 
                                               :start=>Stopwatch.current_log.controller_start})
      super
    end
  end
  ActionController::Base.send :include, ControllerRenderHook

  def self.template
    @@template ||= ::File.read(::File.join(::File.dirname(__FILE__), 'view.erb'))
  end
  def self.template=(value)
    @@template = value
  end

  class Railtie < Rails::Railtie
    initializer "newplugin.initialize" do |app|
      app.config.middleware.use "Rack::LoadSpeed"

      # Start processing
      ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |*args|
        Stopwatch.current_log.reset_query_count
        Stopwatch.current_log.reset_sub_query_count
        Stopwatch.current_log.reset_sub_queries
        Stopwatch.current_log.reset_events
        Stopwatch.current_log.controller_start = Time.now
      end

      # Every query
      ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
        if payload[:name] !~ /^CACHE| Indexes$/
          event = ActiveSupport::Notifications::Event.new(name, start, finish, id, payload)
          Stopwatch.current_log.increment_query_count
          Stopwatch.current_log.add_sub_query event
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
        stopwatch_event.queries = Stopwatch.current_log.sub_queries
        Stopwatch.current_log.events << stopwatch_event
        Stopwatch.current_log.reset_sub_queries
      end

      # End of processing
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
        Stopwatch.current_log.event = ActiveSupport::Notifications::Event.new(*args)
      end
    end
  end
end
