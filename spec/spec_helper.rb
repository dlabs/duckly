require "bundler/setup"
require 'spork'

Spork.prefork do
  ENV["APP_ENV"] ||= 'test'
  require "vcr"
  require "pry"
  require 'active_support/core_ext/string'
  require 'dotenv'
  Dotenv.load

  # Dir["spec/support/**/*.rb"].each {|f| require f}

  VCR.configure do |c|
    c.cassette_library_dir = 'spec/vcr_cassettes'
    c.hook_into :webmock
    c.ignore_localhost = true
    # c.ignore_request { |req| req.uri.starts_with?('https://graph') }
    c.default_cassette_options = {
      decode_compressed_response: true,
      record: :all #:new_episodes
    }
    c.configure_rspec_metadata!

    c.allow_http_connections_when_no_cassette = true

    c.after_http_request(:ignored?) do |request, response|
      puts "Request: #{request.method} #{request.uri}"
      # puts "Response: #{response.status.code}"
    end
  end

  RSpec.configure do |config|

    config.filter_run_excluding(no_ci: true) if ENV['CIRCLECI'] == 'true'
    config.filter_run_including(focus: true) unless (ENV['CI'] == 'true') || (ENV['CIRCLECI'] == 'true')

    config.run_all_when_everything_filtered = true
    config.treat_symbols_as_metadata_keys_with_true_values = true

    config.around(:each, :vcr) do |example|
      name = example.metadata[:full_description].strip.split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
      options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
      # options.merge!({record: :all})
      VCR.use_cassette(name, options) do
        example.call
      end
    end

  end
end

Spork.each_run do

end
