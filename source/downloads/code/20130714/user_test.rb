# encoding: utf-8
require 'test_helper'

class UserTest < ActiveSupport::TestCase

  it "Should create " do
    user = create(:user, age: 19)

    assert_equal 19, user.age
  end

  it "Should add age" do
    age = user.age

    user.age_add

    assert_equal age + 1, user.age
  end

end