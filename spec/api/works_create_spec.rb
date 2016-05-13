require 'rails_helper'

RSpec.describe 'POST /api/works' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:company){ create :company }
  let(:people){ Array.new(2){ create :person } }

  let :minimal_work do
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

  let :full_work do
    minimal_work.merge({
      numberOfItems: 1,
      titles: [
        { text: 'A Tale of Two Cities', language: 'en' },
        { text: 'Le Conte de deux cités', language: 'fr' }
      ],
      descriptions: [
        { text: 'Foo bar baz.', language: 'en' },
        { text: 'Qux corge grault.', language: 'fr' }
      ],
      relationships: [
        { relation: 'artist', personId: people[0].api_id },
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
    })
  end

  let(:protected_call){ ->(h){ post '/api/works', minimal_work, h } }
  it_behaves_like "a protected resource"

  it "should create a minimal work" do

    create_languages :en

    expect_changes events: 1, works: 1, work_titles: 1 do
      post_work minimal_work
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_work.merge({
      links: [],
      relationships: [],
      properties: {},
      titles: with_api_id(minimal_work[:titles])
    }), 6)

    work = expect_work json, creator: user
    expect_model_event :create, user, work
  end

  it "should create a full work" do

    people
    company
    create_languages :en, :fr

    expect_changes events: 1, works: 1, work_descriptions: 2, work_links: 3, work_people: 2, work_titles: 2 do
      post_work full_work
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(full_work.merge({
      relationships: full_work[:relationships].collect{ |r|
        if r.key? :personId
          r.merge person: PersonPolicy.new(:app, people.find{ |p| p.api_id == r[:personId] }).serializer.serialize
        elsif r.key? :companyId
          r.merge company: CompanyPolicy.new(:app, company).serializer.serialize
        else
          r
        end
      },
      titles: with_api_id(full_work[:titles])
    }).except(:descriptions), 6)

    work = expect_work json, creator: user
    expect_model_event :create, user, work
  end

  def post_work body
    post '/api/works', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
