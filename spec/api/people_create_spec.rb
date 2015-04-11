require 'rails_helper'

RSpec.describe 'POST /api/people' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }

  let :minimal_person do
    {
      firstNames: 'Robert',
      lastName: 'Smith'
    }
  end

  let :full_person do
    minimal_person.merge({
      pseudonym: 'Bob',
    })
  end

  let :unnamed_person do
    {
      pseudonym: 'Foo'
    }
  end

  let(:protected_call){ ->(h){ post '/api/people', JSON.dump(minimal_person), h.merge('CONTENT_TYPE' => 'application/json') } }
  it_behaves_like "a protected resource"

  it "should create a minimal person" do
    expect_changes events: 1, people: 1 do
      post_person minimal_person
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_person)

    person = expect_person json, creator: user
    expect_model_event :create, user, person
  end

  it "should create a full person" do
    expect_changes events: 1, people: 1 do
      post_person full_person
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(full_person)

    person = expect_person json, creator: user
    expect_model_event :create, user, person
  end

  it "should create an unnamed person" do
    expect_changes events: 1, people: 1 do
      post_person unnamed_person
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(unnamed_person)

    person = expect_person json, creator: user
    expect_model_event :create, user, person
  end

  def post_person body
    post '/api/people', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
