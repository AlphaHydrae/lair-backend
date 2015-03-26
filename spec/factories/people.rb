# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :first_names do |n|
    "John #{n}"
  end

  factory :person do
    last_name "Doe"
    first_names{ generate :first_names }
    creator
  end
end
