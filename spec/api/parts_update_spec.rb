require 'rails_helper'

RSpec.describe 'PATCH /api/parts/{id}' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:languages){ create_languages :en, :fr, :ja }
  let(:item){ create :item, creator: creator, language: languages[0] }
  let(:other_item){ create :item, creator: creator, language: languages[0] }
  let(:part){ create :book, item: item, creator: creator, language: languages[0] }

  let! :original_version do
    part.to_builder.attributes!
  end

  let :minimal_update do
    {
      originalYear: 2002,
      year: 2003,
      edition: 'Collector'
    }.with_indifferent_access
  end

  let :full_update do
    minimal_update.merge({
      id: part.api_id,
      itemId: other_item.api_id,
      titleId: nil,
      customTitle: 'foo',
      customTitleLanguage: languages[1].tag,
      language: languages[2].tag,
      start: 2,
      end: 3,
      version: 2,
      format: 'Paperback',
      length: 750,
      tags: {
        foo: 'bar',
        baz: 'qux'
      }
    })
  end

  let(:protected_call){ ->(h){ patch "/api/parts/#{part.api_id}", minimal_update, h } }
  it_behaves_like "a protected resource"

  it "should partially update an part" do

    expect_changes events: 1 do
      patch_part part, minimal_update
      expect(response.status).to eq(200)
    end

    json = expect_json original_version.merge(minimal_update)
    expect_part json, creator: creator, updater: user
    expect_model_event :update, user, part, previous_version: original_version
  end

  it "should fully update an part" do

    update = full_update

    expect_changes events: 1 do
      patch_part part, update
      expect(response.status).to eq(200)
    end

    json = expect_json full_update.tap{ |u|
      u.delete :titleId
      u[:title] = { text: full_update[:customTitle], language: full_update[:customTitleLanguage] }
    }

    expect_part json, creator: creator, updater: user
    expect_model_event :update, user, part, previous_version: original_version
  end

  def patch_part part, updates
    patch "/api/parts/#{part.api_id}", JSON.dump(updates), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
