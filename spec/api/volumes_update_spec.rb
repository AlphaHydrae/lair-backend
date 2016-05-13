require 'rails_helper'

RSpec.describe 'PATCH /api/items/{id}' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let(:languages){ create_languages :en, :fr, :ja }
  let(:work){ create :work, creator: creator, language: languages[0], start_year: 2000, end_year: 2003 }
  let(:other_work){ create :work, creator: creator, language: languages[0], start_year: 2000, end_year: 2002 }
  let(:item){ create :volume, work: work, creator: creator, language: languages[0] }

  let! :original_version do
    VolumePolicy.new(:app, item).serializer.serialize
  end

  let :minimal_update do
    {
      originalReleaseDate: '2002-11',
      releaseDate: '2003-09-20',
      edition: 'Collector'
    }.with_indifferent_access
  end

  let :full_update do
    minimal_update.merge({
      id: item.api_id,
      workId: other_work.api_id,
      titleId: other_work.titles.first.api_id,
      customTitle: 'foo',
      customTitleLanguage: languages[1].tag,
      language: languages[2].tag,
      start: 2,
      end: 3,
      version: 2,
      format: 'Paperback',
      length: 750,
      properties: {
        foo: 'bar',
        baz: %w(qux corge)
      }
    })
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

    expect_changes events: 1 do
      patch_item item, update
      expect(response.status).to eq(200)
    end

    json = expect_json full_update.tap{ |u|
      u[:type] = 'volume'
      u[:title] = { id: other_work.titles.first.api_id, text: full_update[:customTitle], language: full_update[:customTitleLanguage] }
    }

    expect_item json, creator: creator, updater: user
    expect_model_event :update, user, item, previous_version: original_version
  end

  describe "with a work that has a start and end year" do
    let(:work){ create :work, creator: creator, language: languages[0], start_year: 2000, end_year: 2002 }

    it "should set the work's start year when updated if the original release date is older" do
      work_original_version = WorkPolicy.new(:app, work).serializer.serialize
      patch_data = minimal_update.merge originalReleaseDate: '1999'

      expect_changes events: 2 do
        patch_item item, patch_data
        expect(response.status).to eq(200)
      end

      json = expect_json original_version.merge(patch_data)

      expect_item json, creator: creator, updater: user
      expect_model_event :update, user, item, previous_version: original_version

      expect_work work_original_version.merge('startYear' => 1999), creator: creator, updater: user
      expect_model_event :update, user, work, previous_version: work_original_version
    end

    it "should set the work's end year when updated if the original release date is newer" do
      work_original_version = WorkPolicy.new(:app, work).serializer.serialize
      patch_data = minimal_update.merge originalReleaseDate: '2003'

      expect_changes events: 2 do
        patch_item item, patch_data
        expect(response.status).to eq(200)
      end

      json = expect_json original_version.merge(patch_data)

      expect_item json, creator: creator, updater: user
      expect_model_event :update, user, item, previous_version: original_version

      expect_work work_original_version.merge('endYear' => 2003), creator: creator, updater: user
      expect_model_event :update, user, work, previous_version: work_original_version
    end
  end

  def patch_item item, updates
    patch "/api/items/#{item.api_id}", JSON.dump(updates), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
