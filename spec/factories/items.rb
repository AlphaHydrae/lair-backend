# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :item do
    transient do
      titles([ 'A Tale of Two Cities' ])
      links([])
      descriptions([])
      relationships([])
    end

    category 'book'
    start_year 2000
    end_year 2000
    number_of_parts 0
    language
    creator

    before :create do |item,evaluator|
      evaluator.titles.each do |title|

        title = if title.kind_of? Hash
          OpenStruct.new({ language: item.language }.merge(title))
        elsif title.kind_of? String
          OpenStruct.new contents: title, language: item.language
        else
          raise "Unsupported item factory title type #{title.class}"
        end

        item.titles << build(:item_title, item: item, contents: title.contents, language: title.language, display_position: 0)
      end

      evaluator.links.each do |link|

        link = if link.kind_of? Hash
          OpenStruct.new({ language: item.language }.merge(link))
        elsif link.kind_of? String
          OpenStruct.new url: link, language: item.language
        else
          raise "Unsupported item factory link type #{link.class}"
        end

        item.links << build(:item_link, item: item, url: link.url, language: link.language)
      end

      evaluator.descriptions.each do |description|

        description = if description.kind_of? Hash
          OpenStruct.new({ language: item.language }.merge(description))
        elsif description.kind_of? String
          OpenStruct.new contents: description, language: item.language
        else
          raise "Unsupported item factory description type #{description.class}"
        end

        item.descriptions << build(:item_description, item: item, contents: description.contents, language: description.language)
      end

      evaluator.relationships.each do |relationship|

        relationship = if relationship.kind_of? Hash
          OpenStruct.new relationship
        elsif relationship.kind_of? String
          OpenStruct.new contents: relationship
        else
          raise "Unsupported item factory relationship type #{relationship.class}"
        end

        relationship.person ||= create(:person)

        item.relationships << build(:item_person, item: item, contents: relationship.contents, person: relationship.person)
      end
    end

    after :create do |item,evaluator|
      item.update_column :original_title_id, item.titles.first.id
    end
  end
end
