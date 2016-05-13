require 'rails_helper'

RSpec.describe 'PATCH /api/items/{id}' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:people){ Array.new(2){ create :person } }
  let(:languages){ create_languages :en, :fr, :de, 'fr-CH' }
  let(:item){ create :item, creator: creator, language: languages[0], titles: [ 'A Tale of Two Cities', { contents: 'Le Conte de deux cités', language: languages[1] } ], links: [ 'http://foo.example.com' ] }

  let! :original_version do
    ItemPolicy.new(:app, item).serializer.serialize
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
        { text: 'Eine Geschichte von Zwei Städten', language: 'de' },
        { id: item.titles[1].api_id, text: 'Le Conte de deux cités', language: 'fr-CH' },
        { id: item.titles[0].api_id, text: 'A Tale of Three Cities', language: 'en' }
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
      patch_item item, minimal_update
      expect(response.status).to eq(200)
    end

    json = expect_json original_version.merge(minimal_update)
    expect_item json, creator: creator, updater: user
    expect_model_event :update, user, item, previous_version: original_version
  end

  it "should fully update an item" do

    update = full_update

    expect_changes events: 1, item_links: 2, item_people: 2, item_titles: 1 do
      patch_item item, update
      expect(response.status).to eq(200)
    end

    json = expect_json full_update.tap{ |u|
      u[:titles] = with_api_id u[:titles]
      u[:relationships].each.with_index do |rel,i|
        rel[:person] = PersonPolicy.new(:app, people[i]).serializer.serialize
      end
    }

    expect_item json, creator: creator, updater: user
    expect_model_event :update, user, item, previous_version: original_version
  end

  def patch_item item, updates
    patch "/api/items/#{item.api_id}", JSON.dump(updates), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
