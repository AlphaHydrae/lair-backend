module Lair

  class API < Grape::API
    version 'v1', using: :accept_version_header, vendor: 'lair'
    format :json

    cascade false
    rescue_from :all do |e|
      if Rails.env != 'production'
        puts e.message
        puts e.backtrace.join("\n")
      end
      Rack::Response.new([ JSON.dump({ errors: [ { message: e.message } ] }) ], 500, { "Content-type" => "application/json" }).finish
    end

    helpers AuthenticationHelper
    helpers do
      def language iso_code
        Language.find_or_create_by(iso_code: iso_code)
      end

      def authenticate!
        authenticate_with_header headers['Authorization'], required: false
      end

      def current_user
        User.where(email: @auth_token['iss']).first!
      end
    end

    before do
      authenticate!
    end

    get :ping do
      'pong'
    end

    namespace :ownerships do

      post do

        item = Item.where(key: params[:itemKey]).first!
        user = params.key?(:userKey) ? User.where(key: params[:userKey]).first! : current_user

        Ownership.transaction do
          ownership = Ownership.new item: item, user: user
          ownership.gotten_at = Time.parse(params[:gottenAt]) if params[:gottenAt]

          ownership.save!
          ownership.to_builder.attributes!
        end
      end
    end

    namespace :parts do
      post do

        item = Item.where(key: params[:itemKey]).first!
        title = item.titles.where(key: params[:titleKey]).first!
        language = language(params[:language])

        ItemPart.transaction do
          part = Book.new
          part.item = item
          part.title = title
          part.language = language
          part.range_start = params[:start] if params.key?(:start)
          part.range_end = params[:end] if params.key?(:end)
          part.edition = params[:edition]
          part.version = params[:version] if params.key?(:version)
          part.format = params[:format] if params.key?(:format)
          part.length = params[:length] if params.key?(:length)
          part.publisher = params[:publisher] if params.key?(:publisher)
          part.isbn = params[:isbn] if params.key?(:isbn)
          part.save!

          part.to_builder.attributes!
        end
      end

      get do
        item = Item.where(key: params[:itemKey]).first!
        ItemPart.joins(:item).where('items.id = ?', item.id).order('item_parts.range_start asc').includes(:title, :language).all.to_a.collect{ |item| item.to_builder.attributes! }
      end
    end

    namespace :items do
      post do
        language = language(params[:language])

        Item.transaction do
          item = Item.new category: params[:category], start_year: params[:startYear], language: language
          item.end_year = params[:endYear] if params.key?(:endYear)
          item.number_of_parts = params[:numberOfParts] if params.key?(:numberOfParts)

          params[:titles].each.with_index do |title,i|
            title = item.titles.build contents: title[:text], language: language(title[:language]), display_position: i
          end

          if params[:links].kind_of?(Array)
            params[:links].each.with_index do |link,i|
              options = { url: link[:url] }
              options[:language] = language(link[:language]) if link.key? :language
              link = item.links.build options
            end
          end

          if params[:decriptions].kind_of?(Array)
            params[:descriptions].each.with_index do |description,i|
              description = item.descriptions.build contents: description[:text], language: language(description[:language])
            end
          end

          item.save!

          item.original_title = item.titles.first
          item.save!

          item.to_builder.attributes!
        end
      end

      get do

        limit = params[:pageSize].to_i
        limit = 10 if limit < 1

        offset = (params[:page].to_i - 1) * limit
        offset = 0 if offset < 1

        header 'X-Pagination-Total', Item.count(:all).to_s

        Item.joins(:titles).where('item_titles.id = items.original_title_id').order('item_titles.contents asc').offset(offset).limit(limit).includes(:titles).all.to_a.collect{ |item| item.to_builder.attributes! }
      end

      namespace '/:itemId' do
        get do
          Item.where(key: params[:itemId]).includes(:titles).first!.to_builder.attributes!
        end

        namespace '/titles' do

          namespace '/:titleId' do
            patch do
              title = ItemTitle.joins(:item).where('items.key = ? AND item_titles.key = ?', params[:itemId], params[:titleId]).first!
              title.contents = params[:text] if params.key? :text
              title.save!
              title.to_builder.attributes!
            end
          end
        end
      end
    end
  end
end
