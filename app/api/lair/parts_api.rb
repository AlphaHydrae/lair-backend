module Lair
  class PartsApi < Grape::API
    namespace :parts do
      post do
        authorize! ItemPart, :create

        part = Book.new creator: current_user

        # TODO: update item number of parts & year if applicable

        ItemPart.transaction do
          item = Item.where(api_id: params[:itemId]).first!
          part.item = item

          part.title = params[:titleId].present? ? item.titles.where(api_id: params[:titleId]).first! : nil if params.key? :titleId
          part.custom_title = params[:customTitle] if params.key? :customTitle
          part.custom_title_language = params[:customTitleLanguage].present? ? language(params[:customTitleLanguage]) : nil if params.key? :customTitleLanguage

          part.language = language params[:language]
          set_image! part, params[:image] if params[:image].kind_of? Hash
          part.year = params[:year] if params.key?(:year)
          part.original_year = params[:originalYear] if params.key?(:originalYear)
          part.range_start = params[:start] if params.key?(:start)
          part.range_end = params[:end] if params.key?(:end)
          part.edition = params[:edition] if params.key?(:edition)
          part.version = params[:version] if params.key?(:version)
          part.format = params[:format] if params.key?(:format)
          part.length = params[:length] if params.key?(:length)
          part.publisher = params[:publisher] if params.key?(:publisher)
          part.isbn = params[:isbn] if params.key?(:isbn)
          part.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != part.tags
          part.save!
        end

        part.to_builder.attributes!
      end

      helpers do
        def search_parts
          limit = params[:pageSize].to_i
          limit = 10 if limit < 1

          page = params[:page].to_i
          offset = (page - 1) * limit
          if offset < 1
            page = 1
            offset = 0
          end

          header 'X-Pagination-Page', page.to_s
          header 'X-Pagination-PageSize', limit.to_s
          header 'X-Pagination-Total', ItemPart.count.to_s

          rel = ItemPart
          filtered = false

          if true_flag? :image
            rel = rel.where 'image_id is not null'
            filtered = true
          elsif false_flag? :image
            rel = rel.where 'image_id is null'
            filtered = true
          end

          if params[:itemId].present?
            rel = rel.joins(:item).where('items.api_id = ?', params[:itemId].to_s)
            filtered = true
          end

          if params[:search].present?
            search = "%#{params[:search].to_s.downcase}%"
            rel = rel.where 'LOWER(item_parts.effective_title) LIKE ?', search
            filtered = true
          end

          header 'X-Pagination-FilteredTotal', rel.count.to_s if filtered

          rel.offset(offset).limit(limit)
        end
      end

      head do
        authorize! ItemPart, :index
        search_parts
        nil
      end

      get do
        authorize! ItemPart, :index

        rel = search_parts

        if true_flag? :random
          rel = rel.order 'RANDOM()'
        else
          rel = rel.order 'item_parts.range_start, item_parts.custom_title'
        end

        with_item = true_flag? :withItem
        with_ownerships = true_flag? :ownerships
        image_from_search = true_flag? :imageFromSearch

        includes = [ :image, :language, { title: :language } ]
        includes << :main_image_search if image_from_search

        if with_item
          includes << { item: [ :language, :links, { relationships: :person, titles: :language } ] }
          includes.last[:item] << :main_image_search if image_from_search
        else
          includes << :item
        end

        parts = rel.includes(includes).to_a

        ownerships = if current_user
          Ownership.joins(:item_part).where(item_parts: { id: parts.collect(&:id) }, ownerships: { user_id: current_user.id }).to_a
        else
          nil
        end

        parts.collect{ |part| part.to_builder(current_user: current_user, with_item: with_item, ownerships: ownerships, image_from_search: image_from_search).attributes! }
      end

      namespace '/:partId' do

        helpers do
          def fetch_part!
            ItemPart.where(api_id: params[:partId]).includes([ :title, :language ]).first!
          end

          def current_imageable
            fetch_part!
          end
        end

        get do
          authorize! ItemPart, :show

          part = fetch_part!

          # TODO: handle includes
          with_item = true_flag? :withItem

          ownerships = if current_user
            Ownership.joins(:item_part).where(item_parts: { id: part }, ownerships: { user_id: current_user.id }).to_a
          else
            nil
          end

          part.to_builder(current_user: current_user, with_item: with_item, ownerships: ownerships).attributes!
        end

        include ImageSearchesApi
        include MainImageSearchApi

        patch do
          authorize! ItemPart, :update

          part = fetch_part!
          part.cache_previous_version
          part.updater = current_user

          ItemPart.transaction do
            part.item = Item.where(api_id: params[:itemId]).first! if params.key? :itemId

            part.title = params[:titleId].present? ? part.item.titles.where(api_id: params[:titleId]).first! : nil if params.key? :titleId
            part.custom_title = params[:customTitle] if params.key? :customTitle
            part.custom_title_language = params[:customTitleLanguage].present? ? language(params[:customTitleLanguage]) : nil if params.key? :customTitleLanguage

            set_image! part, params[:image] if params[:image].kind_of? Hash
            part.language = language params[:language] if params.key? :language
            part.range_start = params[:start] if params.key? :start
            part.range_end = params[:end] if params.key? :end
            %i(year originalYear edition version format length publisher isbn).each do |attr|
              part.send "#{attr.to_s.underscore}=", params[attr] if params.key? attr
            end
            part.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != part.tags
            part.save!
          end

          with_item = true_flag? :withItem
          part.to_builder(with_item: with_item).attributes!
        end
      end
    end
  end
end
