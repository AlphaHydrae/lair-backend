FactoryGirl.define do
  sequence :company_name do |n|
    "Company #{n}"
  end

  factory :company do
    name{ generate :company_name }
    creator
  end
end
