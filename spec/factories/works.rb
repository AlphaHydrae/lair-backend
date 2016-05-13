FactoryGirl.define do
  factory :work do
    transient do
      titles([ 'A Tale of Two Cities' ])
      links([])
      descriptions([])
      relationships([])
    end

    category 'book'
    start_year 2000
    end_year 2000
    number_of_items 0
    language
    creator

    before :create do |work,evaluator|
      evaluator.titles.each.with_index do |title,i|

        title = if title.kind_of? Hash
          OpenStruct.new({ language: work.language }.merge(title))
        elsif title.kind_of? String
          OpenStruct.new contents: title, language: work.language
        else
          raise "Unsupported work factory title type #{title.class}"
        end

        work.titles << build(:work_title, work: work, contents: title.contents, language: title.language, display_position: i)
      end

      evaluator.links.each do |link|

        link = if link.kind_of? Hash
          OpenStruct.new link
        elsif link.kind_of? String
          OpenStruct.new url: link
        else
          raise "Unsupported work factory link type #{link.class}"
        end

        work.links << build(:work_link, work: work, url: link.url, language: link.language)
      end

      evaluator.descriptions.each do |description|

        description = if description.kind_of? Hash
          OpenStruct.new({ language: work.language }.merge(description))
        elsif description.kind_of? String
          OpenStruct.new contents: description, language: work.language
        else
          raise "Unsupported work factory description type #{description.class}"
        end

        work.descriptions << build(:work_description, work: work, contents: description.contents, language: description.language)
      end

      evaluator.relationships.each do |relationship|

        relationship = if relationship.kind_of? Hash
          OpenStruct.new relationship
        elsif relationship.kind_of? String
          OpenStruct.new contents: relationship
        else
          raise "Unsupported work factory relationship type #{relationship.class}"
        end

        relationship.person ||= create(:person)

        work.relationships << build(:work_person, work: work, contents: relationship.contents, person: relationship.person)
      end
    end

    after :create do |work,evaluator|
      work.update_column :original_title_id, work.titles.first.id
    end
  end
end
