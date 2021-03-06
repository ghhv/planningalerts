# frozen_string_literal: true

require "simplecov"

SimpleCov.start("rails") do
  add_filter "app/admin"
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "email_spec"
require "rspec/active_model/mocks"

capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
  "chromeOptions" => {
    "args" => ["--headless", "--disable-gpu"]
  }
)

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.javascript_driver = :chrome
Capybara.server = :webrick

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  # This will by default record new web requests in VCR. We can see
  # that this is happened because the files in spec/fixtures/vcr_cassettes
  # get appended to
  c.default_cassette_options = { record: :new_episodes }
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to this feature using this
  # snippet:
  config.infer_spec_type_from_file_location!

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # This DatabaseCleaner setup is customised for our use of a javascript driver
  # as part of our feature tests using Capybara
  # https://github.com/DatabaseCleaner/database_cleaner#rspec-with-capybara-example
  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, truncation: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, type: :feature) do
    # :rack_test driver's Rack app under test shares database connection
    # with the specs, so continue to use transaction strategy for speed.
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test

    unless driver_shares_db_connection_with_specs
      # Driver is probably for an external browser with an app
      # under test that does *not* share a database connection with the
      # specs, so use truncation strategy.
      DatabaseCleaner.strategy = :truncation
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # This is a workaround for a strange thing where ActionMailer::Base.deliveries isn't being
  # cleared out correctly in feature specs. So, do it here for everything.
  config.before(:each) do
    ActionMailer::Base.deliveries = []
  end

  config.include EmailSpec::Helpers
  config.include EmailSpec::Matchers
  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include SessionHelpers, type: :feature
  config.include EnvHelpers
  config.include MockLocationHelpers
  config.include AutocompleteHelpers
end
