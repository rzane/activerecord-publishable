conn = ActiveRecord::Base.connection

[:foos, :bars].each do |table|
  conn.create_table table, force: true do |t|
    t.string :name
  end
end

class Foo < ActiveRecord::Base
  include Streaming::Model
end

class Bar < ActiveRecord::Base
  include Streaming::Model
end

# Create some ActiveModel::Serializers (for integration testing)
class FooSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class OtherFooSerializer < FooSerializer; end
