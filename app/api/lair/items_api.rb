module Lair
  class ItemsApi < Grape::API
    helpers TitleHelpers

    helpers do
      def update_languages! item, type

        json_key = "#{type.to_s.camelize(:lower)}Languages".to_sym
        return unless params[json_key].kind_of? Array

        association = "#{type}_languages".to_sym
        item.send "#{association}=", params[json_key].collect{ |l| language(l.to_s) }
      end

      def set_date_with_precision! record, attr
        value = params[attr.to_s.camelize(:lower)]
        if value.to_s.try :match, /\A\d+(?:-[01]\d(?:-[0123]\d)?)?\Z/

          date_string, precision = case value.split('-').length
          when 1
            [ "#{value}-01-01", 'y' ]
          when 2
            [ "#{value}-01", 'm' ]
          else
            [ value.to_s, 'd' ]
          end

          record.send "#{attr}=", Date.iso8601(date_string)
          record.send "#{attr}_precision=", precision
        end
      end

      def update_record_from_params record
        record.work = Work.where(api_id: params[:workId]).first! if params.key? :workId

        record.work_title = params[:workTitleId].present? ? record.work.titles.where(api_id: params[:workTitleId]).first! : nil if params.key? :workTitleId

        update_titles_from_params record

        set_image! record, params[:image] if params[:image].kind_of? Hash

        record.language = language params[:language] if params.key? :language

        record.range_start = params[:start] if params.key? :start
        record.range_end = params[:end] if params.key? :end

        %i(edition version format length publisher isbn).each do |attr|
          record.send "#{attr.to_s.underscore}=", params[attr] if params.key? attr
        end

        record.set_properties_from_params params[:properties]

        set_date_with_precision! record, :release_date
        set_date_with_precision! record, :original_release_date

        if record.kind_of? Volume
          record.publisher = params[:publisher] if params.key? :publisher
          record.version = params[:version] if params.key? :version
          record.isbn = params[:isbn] if params.key? :isbn
        elsif record.kind_of? Issue
          record.publisher = params[:publisher] if params.key? :publisher
          record.issn = params[:issn] if params.key? :issn
        elsif record.kind_of? Video
          update_languages! record, :audio
          update_languages! record, :subtitle
        end
      end
    end

    namespace :items do
      post do
        authorize! Item, :create

        type = params[:type].to_s

        item = if type == 'volume'
          Volume.new creator: current_user
        elsif type == 'issue'
          Issue.new creator: current_user
        elsif type == 'video'
          Video.new creator: current_user
        else
          raise "Unsupported item type #{type.inspect}"
        end

        Item.transaction do
          update_record_from_params item
          item.save!
        end

        serialize item
      end

      helpers do
        def search_items
          rel = Item

          rel = paginated rel do |rel|

            work_joined = false
            ownerships_joined = false

            if params[:categories].present?
              rel = rel.joins :work unless work_joined
              work_joined = true
              rel = rel.where 'works.category IN (?)', Array.wrap(params[:categories]).collect(&:to_s).select(&:present?)
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

              unless work_joined
                work_joined = true
                rel = rel.joins :work
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

            if params[:workId].present?
              rel = rel.joins :work unless work_joined
              work_joined = true
              rel = rel.where('works.api_id = ?', params[:workId].to_s)
            end

            if params[:language].present?
              rel = rel.joins(:language).where 'languages.tag = ?', params[:language].to_s
            end

            if params[:rangeStart].present?
              rel = rel.where 'items.range_start = ?', params[:rangeStart].to_s.to_i
            end

            if params[:rangeEnd].present?
              rel = rel.where 'items.range_end = ?', params[:rangeEnd].to_s.to_i
            end

            if params[:search].present?
              search = "%#{params[:search].to_s.downcase}%"
              rel = rel.where 'LOWER(items.sortable_title) LIKE ?', search
            end

            rel
          end

          rel
        end
      end

      head do
        authorize! Item, :index
        search_items
        nil
      end

      get do
        authorize! Item, :index

        rel = search_items

        if params[:collectionId].present?
          rel = rel.group 'items.id'
        end

        if true_flag? :random
          rel = rel.order 'RANDOM()'
        elsif true_flag? :latest # TODO: implement generic order
          rel = rel.order 'items.range_start DESC, items.created_at DESC'
        else
          rel = rel.order 'items.sortable_title'
        end

        with_work = true_flag? :withWork
        with_ownerships = true_flag? :ownerships
        image_from_search = true_flag? :imageFromSearch

        includes = [ :image, :language, { titles: :language, work_title: :language } ]
        includes << :last_image_search if image_from_search

        if with_work
          includes << { work: [ :language, :links, { person_relationships: :person, company_relationships: :company, titles: :language } ] }
          includes.last[:work] << :last_image_search if image_from_search
        else
          includes << :work
        end

        items = rel.preload(includes).to_a

        ownerships = if current_user
          Ownership.joins(:item).where(items: { id: items.collect(&:id) }, ownerships: { owned: true, user_id: current_user.id }).to_a
        else
          nil
        end

        options = { with_work: with_work, ownerships: ownerships, image_from_search: image_from_search }
        serialize items, options
      end

      namespace '/:itemId' do

        helpers do
          # TODO: rename to record
          def fetch_item!
            Item.where(api_id: params[:itemId]).includes([ :language, { titles: :language, work_title: :language } ]).first!
          end
        end

        get do
          authorize! Item, :show

          item = fetch_item!

          # TODO: handle includes
          with_work = true_flag? :withWork

          ownerships = if current_user
            Ownership.joins(:item).where(items: { id: item }, ownerships: { owned: true, user_id: current_user.id }).to_a
          else
            nil
          end

          serialize item, current_user: current_user, with_work: with_work, ownerships: ownerships
        end

        patch do
          authorize! Item, :update

          item = fetch_item!
          item.cache_previous_version
          item.updater = current_user

          Item.transaction do
            update_record_from_params item
            item.save!
          end

          with_work = true_flag? :withWork
          serialize item, with_work: with_work
        end
      end
    end
  end
end
