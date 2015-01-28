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
      def language tag
        Language.find_or_create_by(tag: tag)
      end

      def authenticate!
        authenticate_with_header headers['Authorization'], required: false
      end

      def current_user
        User.where(email: @auth_token['iss']).first!
      end
    end

    get :ping do
      authenticate!
      'pong'
    end

    namespace :languages do
      get do
        Language.full_list.collect(&:to_builder).collect(&:attributes!)
      end
    end

    namespace :ownerships do
      post do
        authenticate!

        item = Item.where(api_id: params[:itemId]).first!
        user = params.key?(:userId) ? User.where(api_id: params[:userId]).first! : current_user

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
        authenticate!

        item = Item.where(api_id: params[:itemId]).first!
        title = item.titles.where(api_id: params[:titleId]).first!
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
        item = Item.where(api_id: params[:itemId]).first!
        ItemPart.joins(:item).where('items.id = ?', item.id).order('item_parts.range_start asc').includes(:title, :language).all.to_a.collect{ |item| item.to_builder.attributes! }
      end
    end

    namespace :items do
      post do
        authenticate!
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

        helpers do
          def fetch_item
            Item.where(api_id: params[:itemId]).includes([ :language, { links: [ :language ], titles: [ :language ] } ]).first!
          end
        end

        get do
          fetch_item.to_builder.attributes!
        end

        patch do

          item = fetch_item

          Item.transaction do
            %i(startYear endYear numberOfParts).each do |attr|
              item.send "#{attr.to_s.underscore}=".to_sym, params[attr] if params.key? attr
            end
            item.language = language params[:language] if params.key? :language

            if params.key? :titles
              titles_to_delete = []
              titles_to_add = params[:titles].dup

              item.titles.each do |title|
                title_data = params[:titles].find{ |h| h[:id] == title.api_id }

                if title_data
                  title.contents = title_data[:text] if title_data.key? :text
                  title.language = language title_data[:language] if title_data.key? :language
                  title.display_position = params[:titles].index title_data
                  titles_to_add.delete title_data
                else
                  title.mark_for_destruction
                end
              end

              titles_to_add.each do |title|
                item.titles << item.titles.build(contents: title[:text], language: language(title[:language]), display_position: params[:titles].index(title))
              end
            end

            if params.key? :links
              links_to_add = params[:links]

              item.links.each do |link|
                if link_data = params[:links].find{ |l| l[:url] == link.url }
                  link.language = language link_data[:language] if link_data.key? :language
                  links_to_add.delete link_data
                else
                  link.mark_for_destruction
                end
              end

              links_to_add.each do |link|
                item.links << item.links.build(url: link[:url], language: link[:language] ? language(link[:language]) : nil)
              end
            end

            item.save!
          end

          item.to_builder.attributes!
        end
      end
    end
  end
end
