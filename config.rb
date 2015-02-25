require 'sinatra/base'

module Sinatra
  module Config
    def self.registered(app)
      app.configure do
        app.set :wsrep_state_dir, '/etc/mysql/wsrep'

        app.set(:hostname) { `hostname`.chomp }

        logger = ::Logger.new('log/check.log')
        logger.level = ::Logger::INFO
        app.set :check_logger, logger
        app.set :checkers, {}

        app.set :max_staleness, 10

        app.set :statsd_host, '127.0.0.1'
        app.set :statsd_port, 8125

        app.set :services, [:xdb]
      end

      app.configure :test do
        app.set :connection_settings, {
          host: 'localhost',
          username: 'root',
          database: 'health_check',
          reconnect: true
        }
        app.set :hostname, 'test.local'

        logger = Logger.new('/dev/null')
        logger.level = Logger::DEBUG
        app.set :check_logger, logger

        app.set :statsd_host, '0.0.0.0'
      end

      app.configure :development do
        app.set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
        app.set :connection_settings, {
          host: 'localhost',
          username: 'root',
          database: 'health_check',
          reconnect: true
        } if app.settings.services.include?(:xdb)
        app.set :hostname, 'dev.local'

        logger = Logger.new(STDOUT)
        logger.level = Logger::DEBUG
        app.set :check_logger, logger
      end

      app.configure :production do
        config = YAML.load_file ENV['WHAZZUP_CONFIG']
        app.set :services, config['services'].map(&:to_sym)

        puts app.settings

        app.set :connection_settings, {
          host: 'localhost',
          username: config['connection_settings']['username'],
          password: config['connection_settings']['password'],
          database: 'health_check',
          reconnect: true
        } if app.settings.services.include?(:xdb)
      end
    end
  end
end