require File.expand_path('../resque_ext', __FILE__)

module Trinidad
  module Extensions
    module Resque
      require 'rake'
      require 'resque/tasks'

      class ResqueLifecycleListener
        include Trinidad::Tomcat::LifecycleListener

        def initialize(options)
          @options = options
        end

        def lifecycle_event(event)
          case event.type
          when Trinidad::Tomcat::Lifecycle::BEFORE_START_EVENT
            start_workers
          when Trinidad::Tomcat::Lifecycle::BEFORE_STOP_EVENT
            stop_workers
          end
        end

        def start_workers
          Thread.new do
            load_tasks
            task = configure_workers
            invoke_workers task
          end
        end

        def load_tasks
          Dir.glob(File.join(@options[:path], '**', '*.rb')).each do |path|
            load path
          end
        end

        def configure_workers
          task = 'resque:work'

          if @options[:count]
            ENV['COUNT'] = @options[:count].to_s
            task = 'resque:workers'
          end

          ENV['QUEUES'] ||= @options[:queues]

          ::Resque.redis = @options[:redis_host]

          load @options[:setup] if @options[:setup]
          task
        end

        def invoke_workers(task)
          Rake::Task[task].invoke
        rescue Errno::ECONNREFUSED
          puts "WARN: Cannot connect with Redis. Please restart the server when Redis is up again."
          @redis_econnref = true
        end

        def stop_workers
          return if @redis_econnref # double check redis is connected, otherwise return
          ::Resque.workers.each { |w| w.shutdown! }
        end
      end
    end
  end
end
