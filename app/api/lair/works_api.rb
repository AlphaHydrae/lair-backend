module Lair
  class WorksApi < Grape::API
    helpers TitleHelpers

    namespace :works do
      post do
        authorize! Work, :create
        language = language(params[:language])

        Work.transaction do
          work = Work.new category: params[:category], start_year: params[:startYear], language: language, creator: current_user
          work.end_year = params[:endYear] if params.key?(:endYear)
          work.number_of_items = params[:numberOfItems] if params.key?(:numberOfItems)
          set_image! work, params[:image] if params[:image].kind_of? Hash
          work.set_properties_from_params params[:properties]

          update_titles_from_params work

          if params[:descriptions].kind_of?(Array)
            params[:descriptions].each.with_index do |description,i|
              work.descriptions.build contents: description[:text], language: language(description[:language])
            end
          end

          if params[:relationships].kind_of?(Array)
            params[:relationships].each do |p|
              if p.key? :personId
                work.person_relationships.build relation: p[:relation].to_s.underscore, details: p[:details], person: Person.where(api_id: p[:personId]).first!
              elsif p.key? :companyId
                work.company_relationships.build relation: p[:relation].to_s.underscore, details: p[:details], company: Company.where(api_id: p[:companyId]).first!
              end
            end
          end

          if params[:links].kind_of?(Array)
            params[:links].each.with_index do |link,i|
              options = { url: link[:url] }
              options[:language] = language(link[:language]) if link.key? :language
              work.links.build options
            end
          end

          work.save!
          work.update_columns original_title_id: work.titles.where(display_position: 0).first.id

          serialize work
        end
      end

      helpers do
        def search_works
          rel = Work

          rel = paginated rel do |rel|

            ownerships_joined = false

            if params[:categories].present?
              rel = rel.where 'works.category IN (?)', Array.wrap(params[:categories]).collect(&:to_s).select(&:present?)
            end

            if params[:ownerIds].present?
              unless ownerships_joined
                ownerships_joined = true
                rel = rel.joins items: { ownerships: :user }
              end

              rel = rel.where 'ownerships.owned = ? AND users.api_id IN (?)', true, Array.wrap(params[:ownerIds]).collect(&:to_s).select(&:present?)
            end

            if params[:collectionId].present?
              collection = Collection.where(api_id: params[:collectionId].to_s).first!

              unless ownerships_joined
                ownerships_joined = true
                rel = rel.joins :items
                rel = rel.joins 'LEFT OUTER JOIN ownerships ON items.id = ownerships.item_id'
                rel = rel.joins 'LEFT OUTER JOIN users ON ownerships.user_id = users.id'
              end

              rel = collection.apply rel
            end

            if params[:image].to_s.match /\A(?:1|y|yes|t|true)\Z/i
              rel = rel.where 'works.image_id is not null'
            elsif params[:image].to_s.match /\A(?:0|n|no|f|false)\Z/i
              rel = rel.where 'works.image_id is null'
            end

            if params[:category].present?
              rel = rel.where 'works.category = ?', params[:category].to_s
            end

            rel = rel.joins :titles if params[:title].present? || params[:search].present?

            if params[:title].present?
              rel = rel.where 'LOWER(work_titles.contents) = ?', params[:title].to_s.downcase
            end

            if params[:search].present?
              rel = rel.where 'LOWER(work_titles.contents) LIKE ?', "%#{params[:search].to_s.downcase}%"
            end

            @pagination_filtered_count = rel.count 'distinct works.id'

            rel
          end

          rel
        end
      end

      head do
        authorize! Work, :index
        search_works
        nil
      end

      get do
        authorize! Work, :index
        rel = search_works

        grouped = params[:search].present? || params[:title].present? || params[:collectionId].present? || params[:ownerIds].present?

        if params[:random].to_s.match /\A(?:1|y|yes|t|true)\Z/i
          rel = rel.order 'RANDOM()'
          rel = rel.group 'works.id' if grouped
        else
          rel = rel.joins('INNER JOIN work_titles AS original_titles ON original_titles.id = works.original_title_id').order('original_titles.contents asc')
          rel = rel.group 'works.id, original_titles.id' if grouped
        end

        includes = [ :language, :links, { person_relationships: :person, company_relationships: :company, titles: :language } ]

        image_from_search = true_flag? :imageFromSearch
        includes << :last_image_search if image_from_search

        options = { image_from_search: image_from_search }
        rel = rel.includes(includes)
        serialize load_resources(rel), options
      end

      namespace '/:workId' do

        helpers do
          def record options = {}
            return @record if @record

            rel = Work.where(api_id: params[:workId])

            if options[:includes] == true
              rel = rel.includes([ :language, { links: :language, person_relationships: :person, company_relationships: :company, titles: :language } ])
            elsif options[:includes]
              rel = rel.includes options[:includes]
            end

            @record = rel.first!
          end

          def update_relationships work, type
            return unless params.key? :relationships

            association = "#{type}_relationships".to_sym
            relation_association = type.to_sym
            id_type = "#{type.to_s.camelize(:lower)}Id".to_sym
            relation_model = type.to_s.camelize.constantize

            relationships_to_add = params[:relationships].select{ |r| r.key? id_type }

            work.send(association).each do |relationship|
              if relationship_data = relationships_to_add.find{ |r| r[:relation].to_s.downcase == relationship.normalized_relation && r[id_type] == relationship.send(relation_association).api_id }
                relationships_to_add.delete relationship_data
              else
                relationship.mark_for_destruction
              end
            end

            relationships_to_add.each do |relationship|
              data = { relation: relationship[:relation].to_s.underscore, details: relationship[:details] }
              data[relation_association] = relation_model.where(api_id: relationship[id_type]).first!
              work.send(association).build data
            end
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        patch do
          authorize! record, :update

          work = record
          work.cache_previous_version
          work.updater = current_user
          original_title = nil

          Work.transaction do
            %i(startYear endYear numberOfItems).each do |attr|
              work.send "#{attr.to_s.underscore}=".to_sym, params[attr] if params.key? attr
            end
            work.language = language params[:language] if params.key? :language
            set_image! work, params[:image] if params[:image].kind_of? Hash
            work.set_properties_from_params params[:properties]

            update_titles_from_params work

            update_relationships work, :person
            update_relationships work, :company

            if params.key? :links
              links_to_add = params[:links]

              work.links.each do |link|
                if link_data = params[:links].find{ |l| l[:url] == link.url }
                  link.language = language link_data[:language] if link_data.key? :language
                  links_to_add.delete link_data
                else
                  link.mark_for_destruction
                end
              end

              links_to_add.each do |link|
                work.links.build(url: link[:url], language: link[:language] ? language(link[:language]) : nil)
              end
            end

            work.save!

            original_title = work.titles.find{ |t| t.display_position == 0 }
            if work.original_title_id != original_title.id
              work.original_title = original_title
              work.update_columns original_title_id: original_title.id
            end

            serialize work
          end
        end

        delete do
          authorize! record, :destroy

          hard = true_flag? :hard
          authorize! record, :hard_destroy if hard

          Rails.application.destroy record, current_user, hard: hard do
            if hard
              items_rel = Item.select(:id).where(work_id: record.id)
              items_events_rel = Event.select(:id).where trackable_type: Item.name, trackable_id: items_rel
              other_items_count = Event.where('id NOT IN (?)', items_events_rel).where("previous_version->>'workId' = ?", record.api_id).count
              raise "#{other_items_count} other items were linked to this work" if other_items_count != 0

              ownerships_rel = Ownership.select(:id).joins(:item).where('items.work_id = ?', record.id)
              ownerships_events_rel = Event.select(:id).where trackable_type: Ownership.name, trackable_id: ownerships_rel
              other_ownerships_count = Event.where('id NOT IN (?)', ownerships_events_rel).where("previous_version->>'itemId' IN (?)", items_rel.select(:id, :api_id).collect(&:api_id)).count
              raise "#{other_ownerships_count} other ownerships were linked to this work's items" if other_ownerships_count != 0

              work_events_rel = Event.where trackable_type: Work.name, trackable_id: record.id

              items_events_rel.delete_all
              ownerships_events_rel.delete_all
              work_events_rel.delete_all
            end
          end

          status 204
          nil
        end
      end
    end
  end
end
