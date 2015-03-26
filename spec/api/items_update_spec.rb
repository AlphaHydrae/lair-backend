require 'rails_helper'

RSpec.describe 'PATCH /api/items/{id}' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:headers){ auth_headers user }
  let(:people){ Array.new(2){ create :person } }
  let(:languages){ create_languages :en, :fr, :de, 'fr-CH' }
  let(:item){ create :item, creator: creator, language: languages[0], titles: [ 'A Tale of Two Cities', { contents: 'Le Conte de deux cités', language: languages[1] } ] }

  let! :original_version do
    item.to_builder.attributes!
  end

  let :minimal_update do
    {
      endYear: 2001,
      numberOfParts: 3,
      language: 'fr'
    }.with_indifferent_access
  end

  let :full_update do
    {
      id: item.api_id,
      category: 'book',
      startYear: 2002,
      endYear: 2003,
      language: 'fr',
      numberOfParts: 2,
      titles: [
        { id: item.titles[1].api_id, text: 'Le Conte de deux cités', language: 'fr-CH' },
        { id: item.titles[0].api_id, text: 'A Tale of Three Cities', language: 'en' },
        { text: 'Eine Geschichte von Zwei Städten', language: 'de' }
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
    }.with_indifferent_access
  end

  let(:protected_call){ ->(h){ patch "/api/items/#{item.api_id}", minimal_update, h } }
  it_behaves_like "a protected resource"

  it "should partially update an item" do

    expect_changes events: 1 do
      patch "/api/items/#{item.api_id}", minimal_update, headers
    end

    expect(response.status).to eq(200)

    json = expect_json original_version.merge(minimal_update)
    expect_item json, creator: creator, updater: user
    expect_model_event :update, user, item, previous_version: original_version
  end

  it "should fully update an item" do

    update = full_update

    expect_changes events: 1, item_links: 3, item_people: 2, item_titles: 1 do
      patch "/api/items/#{item.api_id}", update, headers
    end

    expect(response.status).to eq(200)

    json = expect_json full_update.tap{ |u|
      u[:titles] = with_api_id u[:titles]
      u[:relationships].each.with_index{ |rel,i| rel[:person] = people[i].to_builder.attributes! }
    }

    expect_item json, creator: creator, updater: user
    expect_model_event :update, user, item, previous_version: original_version
  end
end
