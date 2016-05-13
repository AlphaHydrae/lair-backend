FactoryGirl.define do
  factory :work_person do
    relation 'author'
    person
    work
  end
end
