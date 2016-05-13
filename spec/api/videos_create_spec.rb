require 'rails_helper'

RSpec.describe 'POST /api/items' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let!(:work){ create :work, category: 'movie', language: languages[0], start_year: 2000, end_year: 2001 }
  let(:languages){ create_languages :en, :fr, :it, :de }

  let :minimal_item do
    {
      type: 'video',
      workId: work.api_id,
      titleId: work.titles.first.api_id,
      language: languages[0].tag,
      originalReleaseDate: '2000'
    }
  end

  let :full_item do
    minimal_item.merge({
      releaseDate: '2001-07',
      start: 1,
      end: 3,
      edition: 'Collector',
      format: 'DVD',
      length: 234,
      audioLanguages: %w(en fr),
      subtitleLanguages: %w(fr it de),
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
      audioLanguages: [],
      subtitleLanguages: [],
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

  def post_item body
    post '/api/items', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
