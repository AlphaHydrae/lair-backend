# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item_person do
    relation 'author'
    person
    item
  end
end
