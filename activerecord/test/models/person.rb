class Person < ActiveRecord::Base
  has_many :readers
  has_many :secure_readers
  has_one  :reader

  has_many :posts, :through => :readers
  has_many :secure_posts, :through => :secure_readers
  has_many :posts_with_no_comments, -> { includes(:comments).where('comments.id is null').references(:comments) },
                                    :through => :readers, :source => :post

  has_many :followers, foreign_key: 'friend_id', class_name: 'Friendship'

  has_many :references
  has_many :bad_references
  has_many :fixed_bad_references, -> { where :favourite => true }, :class_name => 'BadReference'
  has_one  :favourite_reference, -> { where 'favourite=?', true }, :class_name => 'Reference'
  has_many :posts_with_comments_sorted_by_comment_id, -> { includes(:comments).order('comments.id') }, :through => :readers, :source => :post

  has_many :jobs, :through => :references
  has_many :jobs_with_dependent_destroy,    :source => :job, :through => :references, :dependent => :destroy
  has_many :jobs_with_dependent_delete_all, :source => :job, :through => :references, :dependent => :delete_all
  has_many :jobs_with_dependent_nullify,    :source => :job, :through => :references, :dependent => :nullify

  belongs_to :primary_contact, :class_name => 'Person'
  has_many :agents, :class_name => 'Person', :foreign_key => 'primary_contact_id'
  has_many :agents_of_agents, :through => :agents, :source => :agents
  belongs_to :number1_fan, :class_name => 'Person'

  has_many :agents_posts,         :through => :agents,       :source => :posts
  has_many :agents_posts_authors, :through => :agents_posts, :source => :author

  scope :males,   -> { where(:gender => 'M') }
  scope :females, -> { where(:gender => 'F') }
end

class PersonWithDependentDestroyJobs < ActiveRecord::Base
  self.table_name = 'people'

  has_many :references, :foreign_key => :person_id
  has_many :jobs, :source => :job, :through => :references, :dependent => :destroy
end

class PersonWithDependentDeleteAllJobs < ActiveRecord::Base
  self.table_name = 'people'

  has_many :references, :foreign_key => :person_id
  has_many :jobs, :source => :job, :through => :references, :dependent => :delete_all
end

class PersonWithDependentNullifyJobs < ActiveRecord::Base
  self.table_name = 'people'

  has_many :references, :foreign_key => :person_id
  has_many :jobs, :source => :job, :through => :references, :dependent => :nullify
end


class LoosePerson < ActiveRecord::Base
  self.table_name = 'people'
  self.abstract_class = true

  has_one    :best_friend,    :class_name => 'LoosePerson', :foreign_key => :best_friend_id
  belongs_to :best_friend_of, :class_name => 'LoosePerson', :foreign_key => :best_friend_of_id
  has_many   :best_friends,   :class_name => 'LoosePerson', :foreign_key => :best_friend_id

  accepts_nested_attributes_for :best_friend, :best_friend_of, :best_friends
end

class LooseDescendant < LoosePerson; end

class TightPerson < ActiveRecord::Base
  self.table_name = 'people'

  has_one    :best_friend,    :class_name => 'TightPerson', :foreign_key => :best_friend_id
  belongs_to :best_friend_of, :class_name => 'TightPerson', :foreign_key => :best_friend_of_id
  has_many   :best_friends,   :class_name => 'TightPerson', :foreign_key => :best_friend_id

  accepts_nested_attributes_for :best_friend, :best_friend_of, :best_friends
end

class TightDescendant < TightPerson; end

class RichPerson < ActiveRecord::Base
  self.table_name = 'people'

  has_and_belongs_to_many :treasures, :join_table => 'peoples_treasures'
end

class NestedPerson < ActiveRecord::Base
  self.table_name = 'people'

  has_one :best_friend, :class_name => 'NestedPerson', :foreign_key => :best_friend_id
  accepts_nested_attributes_for :best_friend, :update_only => true

  def comments=(new_comments)
    raise RuntimeError
  end

  def best_friend_first_name=(new_name)
    assign_attributes({ :best_friend_attributes => { :first_name => new_name } })
  end
end

class Insure
  INSURES = %W{life annuality}

  def self.load mask
    INSURES.select do |insure|
      (1 << INSURES.index(insure)) & mask > 0
    end
  end

  def self.dump insures
    numbers = insures.map { |insure| INSURES.index(insure) }
    numbers.inject(0) { |sum, n| sum + (1 << n) }
  end
end

class SerializedPerson < ActiveRecord::Base
  self.table_name = 'people'

  serialize :insures, Insure
end
