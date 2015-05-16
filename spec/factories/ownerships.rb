FactoryGirl.define do
  factory :ownership do
    user
    gotten_at{ 3.days.ago }
    creator
  end
end
