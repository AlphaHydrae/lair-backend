FactoryGirl.define do
  factory :volume do
    work
    title{ work.titles.first }
    original_release_date '2000-01-01'
    original_release_date_precision 'y'
    release_date '2001-01-01'
    release_date_precision 'y'
    language{ work.language }
    range_start 1
    range_end 1
    format 'Hardcover'
    length 250
    creator
  end
end
