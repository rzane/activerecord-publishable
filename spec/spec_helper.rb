require 'bundler'
Bundler.require :default

require 'active_record'
require 'minitest/autorun'
require 'mocha/mini_test'

FileUtils.rm_rf File.expand_path('../test.sqlite3', __FILE__)
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'test.sqlite3'
ActiveRecord::Base.raise_in_transactional_callbacks = true

conn = ActiveRecord::Base.connection

[:foos, :bars].each do |table|
  conn.create_table table, force: true do |t|
    t.string :name
  end
end

class Foo < ActiveRecord::Base
  include ActiveRecord::Publishable
end

class Bar < ActiveRecord::Base
  include ActiveRecord::Publishable
end

# Create some ActiveModel::Serializers (for integration testing)
class FooSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class OtherFooSerializer < FooSerializer; end


module MiniTest::Assertions
  def assert_commit_callbacks(expected, klass)
    assert_equal expected, klass._commit_callbacks.select { |cb|
      cb.kind == :after && cb.name == :commit
    }.size
  end
end

Class.infect_an_assertion :assert_commit_callbacks, :must_have_commit_callbacks
