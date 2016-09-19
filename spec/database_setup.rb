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
    t.column :name, :string
  end
end

class Blog < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  has_many :links, :dependent => :destroy
  before_destroy :before_destroy_callback
  acts_as_paranoid
  include CallbackMatcher::ActiveRecordHooks

  private

  def before_destroy_callback
  end
end

class Comment < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :blog
  include CallbackMatcher::ActiveRecordHooks
end

class Link < ActiveRecord::Base
  belongs_to :blog
  include CallbackMatcher::ActiveRecordHooks
end

