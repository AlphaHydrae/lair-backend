require 'rails_helper'

RSpec.describe 'POST /api/parts' do
  let(:user){ create :user }
  let!(:auth_headers){ generate_auth_headers user }
  let!(:item){ create :item, language: languages[0] }
  let(:languages){ create_languages :en, :fr }

  let :minimal_part do
    {
      itemId: item.api_id,
      titleId: item.titles.first.api_id,
      language: languages[0].tag,
      originalYear: 2000
    }
  end

  let :full_part do
    minimal_part.merge({
      year: 2001,
      start: 1,
      end: 3,
      edition: 'Abridged',
      version: 2,
      format: 'Hardcover',
      length: 234,
      publisher: 'HarperCollins',
      isbn: '9783161484100',
      tags: {
        foo: 'bar',
        baz: 'qux',
        corge: 'grault'
      }
    })
  end

  let(:protected_call){ ->(h){ post '/api/parts', JSON.dump(minimal_part), h.merge('CONTENT_TYPE' => 'application/json') } }
  it_behaves_like "a protected resource"

  it "should create a minimal part" do
    expect_changes events: 1, item_parts: 1 do
      post_part minimal_part
      expect(response.status).to eq(201)
    end

    json = expect_json with_api_id(minimal_part).merge({
      title: ItemTitlePolicy.new(:app, item.titles.first).serializer.serialize,
      tags: {}
    })

    part = expect_part json, creator: user
    expect_model_event :create, user, part
  end

  it "should create a full part" do
    expect_changes events: 1, item_parts: 1 do
      post_part full_part
      expect(response.status).to eq(201)
    end

    title = item.titles.first
    json = expect_json with_api_id(full_part).merge({
      title: ItemTitlePolicy.new(:app, title).serializer.serialize.merge('text' => "#{title.contents} 1-3")
    })

    part = expect_part json, creator: user
    expect_model_event :create, user, part
  end

  def post_part body
    post '/api/parts', JSON.dump(body), auth_headers.merge('CONTENT_TYPE' => 'application/json')
  end
end
