require 'rails_helper'

RSpec.describe 'POST /api/items' do
  let(:user){ create :user }
  let(:creator){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let!(:work){ create :work, language: languages[0], start_year: 2000, end_year: 2001, creator: creator }
  let(:languages){ create_languages :en, :fr }

  let :minimal_item do
    {
      type: 'volume',
      workId: work.api_id,
      titleId: work.titles.first.api_id,
      language: languages[0].tag,
      originalReleaseDate: '2000-03'
    }
  end

  let :full_item do
    minimal_item.merge({
      releaseDate: '2001-12-24',
      start: 1,
      end: 3,
      edition: 'Abridged',
      version: 2,
      format: 'Hardcover',
      length: 234,
      publisher: 'HarperCollins',
      isbn: '9783161484100',
      properties: {
        foo: 'bar',
        baz: 'qux',
        corge: %w(grault garply waldo)
      }
    })
  end

  let(:protected_call){ ->(h){ post '/api/items', JSON.dump(minimal_item), h.merge('CONTENT_TYPE' => 'application/json') } }
  it_behaves_like "a protected resource"

  it "should create a minimal item" do
    expect_changes events: 1, items: 1 do
      post_item minimal_item
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_item).merge({
      title: WorkTitlePolicy.new(:app, work.titles.first).serializer.serialize,
      properties: {}
    })

    item = expect_item json, creator: user
    expect_model_event :create, user, item
  end

  it "should create a full item" do
    expect_changes events: 1, items: 1 do
      post_item full_item
      expect(response.status).to eq(201)
    end

    title = work.titles.first
    json = expect_json with_api_id(full_item).merge({
      title: WorkTitlePolicy.new(:app, title).serializer.serialize.merge('text' => "#{title.contents} 1-3")
    })

    item = expect_item json, creator: user
    expect_model_event :create, user, item
  end

  describe "with a work that has no start or end year" do
    let!(:work){ create :work, language: languages[0], start_year: nil, end_year: nil, creator: creator }
    let(:minimal_item){ super().merge originalReleaseDate: '1998-03' }

    it "should set the work's start and end year when created" do
      work_original_version = WorkPolicy.new(:app, work).serializer.serialize

      expect_changes events: 2, items: 1 do
        post_item minimal_item
        expect(response.status).to eq(201)
      end

      json = expect_json with_api_id(minimal_item).merge({
        title: WorkTitlePolicy.new(:app, work.titles.first).serializer.serialize,
        properties: {}
      })

      item = expect_item json, creator: user
      expect_model_event :create, user, item

      expect_work work_original_version.merge('startYear' => 1998, 'endYear' => 1998), creator: creator, updater: user
      expect_model_event :update, user, work, previous_version: work_original_version
    end
  end

  describe "with a work that has a start and end year" do
    let!(:work){ create :work, language: languages[0], start_year: 2000, end_year: 2001, creator: creator }

    it "should set the work's start year when created if the original release date is older" do
      work_original_version = WorkPolicy.new(:app, work).serializer.serialize
      post_data = minimal_item.merge originalReleaseDate: '1998-03'

      expect_changes events: 2, items: 1 do
        post_item post_data
        expect(response.status).to eq(201)
      end

      json = expect_json with_api_id(post_data).merge({
        title: WorkTitlePolicy.new(:app, work.titles.first).serializer.serialize,
        properties: {}
      })

      item = expect_item json, creator: user
      expect_model_event :create, user, item

      expect_work work_original_version.merge('startYear' => 1998), creator: creator, updater: user
      expect_model_event :update, user, work, previous_version: work_original_version
    end

    it "should set the work's end year when created if the original release date is newer" do
      work_original_version = WorkPolicy.new(:app, work).serializer.serialize
      post_data = minimal_item.merge originalReleaseDate: '2012-05-12'

      expect_changes events: 2, items: 1 do
        post_item post_data
        expect(response.status).to eq(201)
      end

      json = expect_json with_api_id(post_data).merge({
        title: WorkTitlePolicy.new(:app, work.titles.first).serializer.serialize,
        properties: {}
      })

      item = expect_item json, creator: user
      expect_model_event :create, user, item

      expect_work work_original_version.merge('endYear' => 2012), creator: creator, updater: user
      expect_model_event :update, user, work, previous_version: work_original_version
    end
  end

  def post_item body
    post '/api/items', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
