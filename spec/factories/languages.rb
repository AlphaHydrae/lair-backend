# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :language, aliases: %i(en) do
    tag 'en'
  end
end
