require 'rails_helper'

RSpec.describe 'PATCH /api/ownerships/{id}' do
  let(:user){ create :user }
  let(:other_user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:languages){ create_languages :en }
  let(:item){ create :item, creator: user, language: languages[0] }
  let(:part){ create :book, creator: user, item: item, language: languages[0] }
  let(:other_part){ create :book, creator: user, item: item, language: languages[0], range_start: 2, range_end: 2 }
  let(:ownership){ create :ownership, creator: creator, user: user, item_part: part }
  let(:now){ Time.now }

  let! :original_version do
    ownership.to_builder.attributes!
  end

  let :minimal_update do
    {
      gottenAt: 5.days.ago.iso8601(3)
    }.with_indifferent_access
  end

  let :full_update do
    {
      id: ownership.api_id,
      partId: other_part.api_id,
      userId: other_user.api_id,
      gottenAt: 7.days.ago.iso8601(3),
      tags: {
        foo: 'bar',
        baz: 'qux'
      }
    }.with_indifferent_access
  end

  let(:protected_call){ ->(h){ patch "/api/ownerships/#{ownership.api_id}", minimal_update, h } }
  it_behaves_like "a protected resource"

  it "should partially update an ownership" do

    expect_changes events: 1 do
      patch_ownership ownership, minimal_update
      expect(response.status).to eq(200)
    end

    json = expect_json original_version.merge(minimal_update)
    expect_ownership json, creator: creator, updater: user
    expect_model_event :update, user, ownership, previous_version: original_version
  end

  it "should fully update an ownership" do

    update = full_update

    expect_changes events: 1 do
      patch_ownership ownership, update
      expect(response.status).to eq(200)
    end

    json = expect_json full_update
    expect_ownership json, creator: creator, updater: user
    expect_model_event :update, user, ownership, previous_version: original_version
  end

  def patch_ownership ownership, updates
    patch "/api/ownerships/#{ownership.api_id}", JSON.dump(updates), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
