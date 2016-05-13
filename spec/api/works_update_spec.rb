require 'rails_helper'

RSpec.describe 'PATCH /api/works/{id}' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:company){ create :company }
  let(:people){ Array.new(2){ create :person } }
  let(:languages){ create_languages :en, :fr, :de, 'fr-CH' }
  let(:work){ create :work, creator: creator, language: languages[0], titles: [ 'A Tale of Two Cities', { contents: 'Le Conte de deux cités', language: languages[1] } ], links: [ 'http://foo.example.com' ] }

  let! :original_version do
    WorkPolicy.new(:app, work).serializer.serialize
  end

  let :minimal_update do
    {
      endYear: 2001,
      numberOfItems: 3,
      language: 'fr'
    }.with_indifferent_access
  end

  let :full_update do
    {
      id: work.api_id,
      category: 'book',
      startYear: 2002,
      endYear: 2003,
      language: 'fr',
      numberOfItems: 2,
      titles: [
        { text: 'Eine Geschichte von Zwei Städten', language: 'de' },
        { id: work.titles[1].api_id, text: 'Le Conte de deux cités', language: 'fr-CH' },
        { id: work.titles[0].api_id, text: 'A Tale of Three Cities', language: 'en' }
      ],
      relationships: [
        { relation: 'author', personId: people[0].api_id },
        { relation: 'author', personId: people[1].api_id },
        { relation: 'publishingCompany', companyId: company.api_id }
      ],
      links: [
        { url: 'http://bar.example.com', language: 'fr' },
        { url: 'http://baz.example.com', language: 'en' },
        { url: 'http://foo.example.com' }
      ],
      properties: {
        foo: 'bar',
        baz: 'qux',
        corge: %w(grault garply waldo)
      }
    }.with_indifferent_access
  end

  let(:protected_call){ ->(h){ patch "/api/works/#{work.api_id}", minimal_update, h } }
  it_behaves_like "a protected resource"

  it "should partially update a work" do

    expect_changes events: 1 do
      patch_work work, minimal_update
      expect(response.status).to eq(200)
    end

    json = expect_json original_version.merge(minimal_update)
    expect_work json, creator: creator, updater: user
    expect_model_event :update, user, work, previous_version: original_version
  end

  it "should fully update a work" do

    update = full_update

    expect_changes events: 1, work_links: 2, work_people: 2, work_titles: 1 do
      patch_work work, update
      expect(response.status).to eq(200)
    end

    json = expect_json full_update.tap{ |u|
      u[:titles] = with_api_id u[:titles]
      u[:relationships].each.with_index do |rel,i|
        if rel.key? :personId
          rel[:person] = PersonPolicy.new(:app, people[i]).serializer.serialize
        elsif rel.key? :companyId
          rel[:company] = CompanyPolicy.new(:app, company).serializer.serialize
        end
      end
    }

    expect_work json, creator: creator, updater: user
    expect_model_event :update, user, work, previous_version: original_version
  end

  def patch_work work, updates
    patch "/api/works/#{work.api_id}", JSON.dump(updates), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
