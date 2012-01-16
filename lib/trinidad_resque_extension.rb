module Trinidad
  module Extensions
    require File.expand_path('../resque_lifecycle_listener', __FILE__)
    module Resque
      VERSION = '0.1.1'
    end

    class ResqueApp < Trinidad::RackupWebApp
      def init_params
        super
        add_parameter_unless_exist 'rackup', "require 'rubygems';require 'resque';require 'resque/server';run Resque::Server.new"
        @params
      end
    end

    class ResqueServerExtension < ServerExtension
      attr_accessor :options

      def initialize(options)
        super
        @options[:redis_host] ||= 'localhost:6379'
        @options[:queues] ||= 'trinidad_resque'
        @options[:path] ||= File.join('lib', 'tasks')
      end

      def configure(tomcat)
        add_resque_listener(tomcat)

        init_resque_web(tomcat) unless @options[:disable_web]

        trap_signals(tomcat)
      end

      def add_resque_listener(tomcat)
        tomcat.host.add_lifecycle_listener(Trinidad::Extensions::Resque::ResqueLifecycleListener.new(@options))
      end

      def init_resque_web(tomcat)
        opts = prepare_options

        app_context = tomcat.addWebapp(opts[:context_path], opts[:web_app_dir])

        web_app = ResqueApp.new({}, opts)

        app_context.add_lifecycle_listener(Trinidad::Lifecycle::Default.new(web_app))
        web_app
      end

      def prepare_options
        # where resque gem is
        resque_path = Gem::GemPathSearcher.new.find('resque').full_gem_path

        opts = {
          :context_path => '/resque',
          :jruby_min_runtimes => 1,
          :jruby_max_runtimes => 2,
          :libs_dir => 'libs',
          :classes_dir => 'classes',
          :public => 'public',
          :environment => 'production'
        }

        opts.deep_merge!(@options)
        opts[:web_app_dir] = File.expand_path('lib/resque/server', resque_path)
        opts
      end

      def trap_signals(tomcat)
        # trap signals and stop tomcat properly to make sure resque is also stopped properly
        trap('INT') do
          ::Resque.workers.each { |w| w.shutdown! }
          tomcat.stop
        end
        trap('TERM') do
          ::Resque.workers.each { |w| w.shutdown! }
          tomcat.stop
        end
      end
    end

    class ResqueOptionsExtension < OptionsExtension
      def configure(parser, default_options)
        default_options[:extensions] ||= {}
        default_options[:extensions][:resque] = {}
      end
    end
  end
end
