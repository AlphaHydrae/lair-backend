FactoryGirl.define do
  sequence :email do |n|
    "john.doe.#{n}@example.com"
  end

  factory :user, aliases: %i(creator) do
    email{ generate :email }
  end
end
