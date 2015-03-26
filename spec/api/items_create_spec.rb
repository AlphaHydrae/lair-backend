require 'rails_helper'

RSpec.describe 'POST /api/items' do
  let(:user){ create :user }
  let(:people){ Array.new(2){ create :person } }
  let!(:headers){ auth_headers user }

  let :minimal_item do
    {
      category: 'book',
      startYear: 2000,
      endYear: 2000,
      language: 'en',
      titles: [
        { text: 'A Tale of Two Cities', language: 'en' }
      ]
    }
  end

  let :maximal_item do
    minimal_item.merge({
      numberOfParts: 1,
      titles: [
        { text: 'A Tale of Two Cities', language: 'en' },
        { text: 'Le Conte de deux cités', language: 'fr' }
      ],
      descriptions: [
        { text: 'Foo bar baz.', language: 'en' },
        { text: 'Qux corge grault.', language: 'fr' }
      ],
      relationships: [
        { relation: 'author', personId: people[0].api_id },
        { relation: 'author', personId: people[1].api_id }
      ],
      links: [
        { url: 'http://bar.example.com', language: 'fr' },
        { url: 'http://baz.example.com', language: 'en' },
        { url: 'http://foo.example.com' }
      ],
      tags: {
        foo: 'bar',
        baz: 'qux',
        corge: 'grault'
      }
    })
  end

  let(:protected_call){ ->(h){ post '/api/items', minimal_item, h } }
  it_behaves_like "a protected resource"

  it "should create a minimal item" do

    create_languages :en

    expect_changes events: 1, items: 1, item_titles: 1 do
      post '/api/items', minimal_item, headers
    end

    expect(response.status).to eq(201)

    json = expect_json with_api_id(minimal_item.merge({
      links: [],
      relationships: [],
      tags: {},
      titles: with_api_id(minimal_item[:titles])
    }), 6)

    item = expect_item json
    expect_model_event :create, user, item
  end

  it "should create a full item" do

    people
    create_languages :en, :fr

    expect_changes events: 1, items: 1, item_descriptions: 2, item_links: 3, item_people: 2, item_titles: 2 do
      post '/api/items', maximal_item, headers
    end

    expect(response.status).to eq(201)

    json = expect_json with_api_id(maximal_item.merge({
      relationships: maximal_item[:relationships].collect{ |r| r.merge person: people.find{ |p| p.api_id == r[:personId] }.to_builder.attributes! },
      titles: with_api_id(maximal_item[:titles])
    }).except(:descriptions), 6)

    item = expect_item json
    expect_model_event :create, user, item
  end
end
