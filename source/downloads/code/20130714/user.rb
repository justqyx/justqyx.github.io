class User < ActiveModel::Base

  validates :name, :age, presence: true 

  def age_add
    self.update_attribute :age, self.age + 1
  end

end