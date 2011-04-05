require 'logger'
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite'])

ActiveRecord::Schema.define(:version => 2) do
  create_table :blogs, :force => true do |t|
    t.column :title, :string
    t.column :body, :string
    t.column :deleted_at, :timestamp
  end
  create_table :comments, :force => true do |t|
    t.column :blog_id, :integer
    t.column :text, :string
    t.column :deleted_at, :timestamp
  end
  create_table :links, :force => true do |t|
    t.column :blog_id, :integer
    t.column :url, :string
  end
end

