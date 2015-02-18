FactoryGirl.define do
  sequence :email do |n|
    "john.doe.#{n}@example.com"
  end

  factory :user do
    email{ generate :email }
  end
end
