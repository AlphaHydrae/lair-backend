require 'rails_helper'

RSpec.describe 'PATCH /api/ownerships/{id}' do
  let(:user){ create :admin }
  let(:other_user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:languages){ create_languages :en }
  let(:work){ create :work, creator: user, language: languages[0] }
  let(:item){ create :volume, creator: user, work: work, language: languages[0] }
  let(:other_item){ create :volume, creator: user, work: work, language: languages[0], range_start: 2, range_end: 2 }
  let(:ownership){ create :ownership, creator: creator, user: user, item: item }
  let(:now){ Time.now }

  let! :original_version do
    OwnershipPolicy.new(:app, ownership).serializer.serialize
  end

  let :minimal_update do
    {
      gottenAt: 5.days.ago.iso8601(3)
    }.with_indifferent_access
  end

  let :full_update do
    {
      id: ownership.api_id,
      itemId: other_item.api_id,
      userId: other_user.api_id,
      gottenAt: 7.days.ago.iso8601(3),
      properties: {
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
