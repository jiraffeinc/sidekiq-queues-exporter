# frozen_string_literal: true

require 'sidekiq/queues/exporter/version'
require 'erb'
require 'sidekiq/api'

module Sidekiq
  module Queues
    module Exporter
      REQUEST_VERB = 'GET'.freeze
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze
      MOUNT_PATH = '/metrics'.freeze
      HEADERS = {'Content-Type' => 'text/plain; version=0.1.0', 'Cache-Control' => 'no-cache'}.freeze

      class << self
        def exports
          @queues = Sidekiq::Queue.all.map do |queue|
            {
              queue_name: queue.name,
              queue_size: queue.size
            }
          end
          template = ERB.new(File.read(File.expand_path('templates/queues.erb', __dir__)))
          template.result(binding).chomp!
        end

        def registered(app)
          app.get(MOUNT_PATH) do
            call(REQUEST_METHOD => REQUEST_VERB)
          end
        end

        def to_app
          Rack::Builder.app do
            map(MOUNT_PATH) do
              run Sidekiq::Queues::Exporter
            end
          end
        end

        def call(env)
          return [404, HEADERS, ['Not found']] if env[REQUEST_METHOD] != REQUEST_VERB

          [200, HEADERS, [exports]]
        end
      end
    end
  end
end
