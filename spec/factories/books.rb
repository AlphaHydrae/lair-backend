# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :book do
    item
    title{ item.titles.first }
    original_year 2000
    year 2001
    language
    range_start 1
    range_end 1
    format 'Hardcover'
    length 250
    creator
  end
end
