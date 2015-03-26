# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_description do
    contents 'Foo Bar Baz'
    language
    item
  end
end
