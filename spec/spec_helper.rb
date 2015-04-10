require 'bundler'
Bundler.require :default
require 'active_record'
require 'minitest/autorun'
require 'mocha/mini_test'

FileUtils.rm_rf File.expand_path('../test.sqlite3', __FILE__)
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'test.sqlite3'
ActiveRecord::Base.raise_in_transactional_callbacks = true

require_relative './support/expectations'
require_relative './support/models'
