FactoryGirl.define :user do
  sequence(:name) { |n| "user name #{n}" }
  sequence(:age, 20) # 20岁以上
end
