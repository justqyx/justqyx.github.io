# encoding: utf-8

ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
require "minitest/mock"
require "minitest/spec"
require "ffaker"

if ENV["COV"]
  require 'simplecov'
  SimpleCov.start 'rails'
end

DatabaseCleaner.strategy = :transaction

class ActiveSupport::TestCase
  extend MiniTest::Spec::DSL # Add some RSpec style helper
  include FactoryGirl::Syntax::Default

  # 全局都能通过访问 user 这个方法来得到一条user数据
  let(:user) { create(:user) }

  setup do
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

end
