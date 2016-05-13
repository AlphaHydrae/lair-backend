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

        serialize part
      end

      helpers do
        def search_parts
          rel = ItemPart

          rel = paginated rel do |rel|

            item_joined = false
            ownerships_joined = false

            if params[:categories].present?
              rel = rel.joins :item unless item_joined
              item_joined = true
              rel = rel.where 'items.category IN (?)', Array.wrap(params[:categories]).collect(&:to_s).select(&:present?)
            end

            if params[:ownerIds].present?
              unless ownerships_joined
                ownerships_joined = true
                rel = rel.joins ownerships: :user
              end

              rel = rel.where 'ownerships.owned = ? AND users.api_id IN (?)', true, Array.wrap(params[:ownerIds]).collect(&:to_s)
            end

            if params[:collectionId].present?
              collection = Collection.where(api_id: params[:collectionId].to_s).first!

              unless item_joined
                item_joined = true
                rel = rel.joins :item
              end

              unless ownerships_joined
                ownerships_joined = true
                rel = rel.joins ownerships: :user
              end

              rel = collection.apply rel
            end

            if true_flag? :image
              rel = rel.where 'image_id is not null'
            elsif false_flag? :image
              rel = rel.where 'image_id is null'
            end

            if params[:itemId].present?
              rel = rel.joins :item unless item_joined
              item_joined = true
              rel = rel.where('items.api_id = ?', params[:itemId].to_s)
            end

            if params[:search].present?
              search = "%#{params[:search].to_s.downcase}%"
              rel = rel.where 'LOWER(item_parts.effective_title) LIKE ?', search
            end

            rel
          end

          rel
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

        if params[:collectionId].present?
          rel = rel.group 'item_parts.id'
        end

        if true_flag? :random
          rel = rel.order 'RANDOM()'
        elsif true_flag? :latest # TODO: implement generic order
          rel = rel.order 'item_parts.range_start DESC, item_parts.created_at DESC'
        else
          # TODO: improve part sorting
          rel = rel.order 'item_parts.effective_title'
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

        # TODO: test preload
        parts = rel.preload(includes).to_a

        ownerships = if current_user
          Ownership.joins(:item_part).where(item_parts: { id: parts.collect(&:id) }, ownerships: { owned: true, user_id: current_user.id }).to_a
        else
          nil
        end

        options = { with_item: with_item, ownerships: ownerships, image_from_search: image_from_search }
        serialize parts, options
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
            Ownership.joins(:item_part).where(item_parts: { id: part }, ownerships: { owned: true, user_id: current_user.id }).to_a
          else
            nil
          end

          serialize part, current_user: current_user, with_item: with_item, ownerships: ownerships
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
          serialize part, with_item: with_item
        end
      end
    end
  end
end
