# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :video do
    work
    title{ work.titles.first }
    original_release_date '2000-01-01'
    original_release_date_precision 'y'
    release_date '2001-01-01'
    release_date_precision 'y'
    language
    range_start 1
    range_end 1
    format 'DVD'
    length 125
    creator
  end
end
