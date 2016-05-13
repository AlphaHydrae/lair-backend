FactoryGirl.define do
  sequence :user_name do |n|
    "user-#{n}"
  end

  sequence :user_email do |n|
    "user.#{n}@example.com"
  end

  factory :user, aliases: %i(creator) do
    name{ generate :user_name }
    email{ generate :user_email }
    active true

    factory :admin do
      roles_mask User.mask_for(:admin)
    end
  end
end
