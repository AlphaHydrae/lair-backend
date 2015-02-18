require 'rails_helper'

RSpec.describe 'POST /api/items' do
  let(:user){ create :user }

  it "should create a minimal item" do
    req = {
      category: 'book',
      startYear: 2000,
      endYear: 2000,
      language: 'en',
      titles: [
        { text: 'A Tale of Two Cities', language: 'en' }
      ]
    }

    headers = auth_headers
    create :language, tag: 'en'

    expect_changes items: 1, item_titles: 1 do
      post '/api/items', req, headers
    end

    expect(response.status).to eq(201)

    expect_json with_api_id(req.merge({
      links: [],
      relationships: [],
      tags: {},
      titles: with_api_id(req[:titles])
    }), 6)
  end

  it "should create a full item" do
    people = Array.new(2){ create :person }

    req = {
      category: 'book',
      startYear: 2000,
      endYear: 2000,
      language: 'en',
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
    }

    headers = auth_headers
    %i(en fr).each{ |tag| create :language, tag: tag }

    expect_changes items: 1, item_titles: 2, item_descriptions: 2, item_links: 3, item_people: 2 do
      post '/api/items', req, headers
    end

    expect(response.status).to eq(201)

    expect_json with_api_id(req.merge({
      relationships: req[:relationships].collect{ |r| r.merge person: people.find{ |p| p.api_id == r[:personId] }.to_builder.attributes! },
      titles: with_api_id(req[:titles])
    }).except(:descriptions), 6)
  end
end
