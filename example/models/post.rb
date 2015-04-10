require 'active_record'
require 'streaming'

# Connect to an in-memory database
ActiveRecord::Base.establish_connection adapter: 'sqlite3',
                                        database: 'db.sqlite3'

ActiveRecord::Base.raise_in_transactional_callbacks = true

conn = ActiveRecord::Base.connection
conn.create_table :posts do |t|
  t.string :content
  t.integer :update_count, default: 0
  t.timestamps null: false
end unless conn.table_exists?(:posts)

# Here's the important part. Define our model and enable streaming.
class Post < ActiveRecord::Base
  include Streaming::Model
  streamable
end
