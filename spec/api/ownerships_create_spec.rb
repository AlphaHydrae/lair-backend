require 'rails_helper'

RSpec.describe 'POST /api/ownerships' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:work){ create :work, creator: user, language: languages[0] }
  let!(:item){ create :volume, creator: user, work: work, language: languages[0] }
  let(:languages){ create_languages :en }
  let(:now){ Time.now }

  let :minimal_ownership do
    {
      itemId: item.api_id,
      userId: user.api_id,
      gottenAt: now.utc.iso8601(3)
    }
  end

  let :full_ownership do
    minimal_ownership.merge({
      properties: {
        foo: 'bar',
        baz: 'qux'
      }
    })
  end

  let(:protected_call){ ->(h){ post '/api/ownerships', JSON.dump(minimal_ownership), h.merge('CONTENT_TYPE' => 'application/json') } }
  it_behaves_like "a protected resource"

  it "should create a minimal ownership" do
    expect_changes events: 1, ownerships: 1 do
      post_ownership minimal_ownership
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_ownership).merge({
      properties: {}
    })

    ownership = expect_ownership json, creator: user
    expect_model_event :create, user, ownership
  end

  it "should create a full ownership" do
    expect_changes events: 1, ownerships: 1 do
      post_ownership full_ownership
      expect(response.status).to eq(201)
    end

    title = work.titles.first
    json = expect_json with_api_id(full_ownership)

    ownership = expect_ownership json, creator: user
    expect_model_event :create, user, ownership
  end

  def post_ownership body
    post '/api/ownerships', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
