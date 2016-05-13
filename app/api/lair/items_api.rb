module Lair
  class ItemsApi < Grape::API
    namespace :items do
      post do
        authorize! Item, :create
        language = language(params[:language])

        Item.transaction do
          item = Item.new category: params[:category], start_year: params[:startYear], language: language, creator: current_user
          item.end_year = params[:endYear] if params.key?(:endYear)
          item.number_of_parts = params[:numberOfParts] if params.key?(:numberOfParts)
          set_image! item, params[:image] if params[:image].kind_of? Hash
          # TODO: check only strings in tags
          item.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != item.tags

          params[:titles].each.with_index do |title,i|
            item.titles.build contents: title[:text], language: language(title[:language]), display_position: i
          end

          if params[:descriptions].kind_of?(Array)
            params[:descriptions].each.with_index do |description,i|
              item.descriptions.build contents: description[:text], language: language(description[:language])
            end
          end

          if params[:relationships].kind_of?(Array)
            params[:relationships].each do |p|
              item.relationships.build relationship: p[:relation], person: Person.where(api_id: p[:personId]).first!
            end
          end

          if params[:links].kind_of?(Array)
            params[:links].each.with_index do |link,i|
              options = { url: link[:url] }
              options[:language] = language(link[:language]) if link.key? :language
              item.links.build options
            end
          end

          item.save!
          item.update_columns original_title_id: item.titles.first.id

          item.to_builder.attributes!
        end
      end

      helpers do
        def search_items
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
          header 'X-Pagination-Total', Item.count.to_s

          rel = Item
          filtered = false

          if params[:image].to_s.match /\A(?:1|y|yes|t|true)\Z/i
            rel = rel.where 'image_id is not null'
            filtered = true
          elsif params[:image].to_s.match /\A(?:0|n|no|f|false)\Z/i
            rel = rel.where 'image_id is null'
            filtered = true
          end

          if params[:category].present?
            rel = rel.where category: params[:category].to_s
            filtered = true
          end

          if params[:search].present?
            rel = rel.joins(:titles).where 'LOWER(item_titles.contents) LIKE ?', "%#{params[:search].to_s.downcase}%"
            filtered = true
          end

          header 'X-Pagination-FilteredTotal', rel.count.to_s if filtered

          rel.offset(offset).limit(limit)
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

        grouped = params[:search].present?

        if params[:random].to_s.match /\A(?:1|y|yes|t|true)\Z/i
          rel = rel.order 'RANDOM()'
          rel = rel.group 'items.id' if grouped
        else
          rel = rel.joins('INNER JOIN item_titles AS original_titles ON original_titles.id = items.original_title_id').order('original_titles.contents asc')
          rel = rel.group 'items.id, original_titles.id' if grouped
        end

        includes = [ :language, :links, { relationships: :person, titles: :language } ]

        image_from_search = true_flag? :imageFromSearch
        includes << :main_image_search if image_from_search

        rel.includes(includes).to_a.collect{ |item| item.to_builder(image_from_search: image_from_search).attributes! }
      end

      namespace '/:itemId' do

        helpers do
          def fetch_item! options = {}
            rel = Item.where(api_id: params[:itemId])

            if options[:includes] == true
              rel = rel.includes([ :language, { links: [ :language ], relationships: [ :person ], titles: [ :language ] } ])
            elsif options[:includes]
              rel = rel.includes options[:includes]
            end

            rel.first!
          end

          def current_imageable
            fetch_item!
          end
        end

        get do
          authorize! Item, :show
          fetch_item!(includes: true).to_builder.attributes!
        end

        include ImageSearchesApi
        include MainImageSearchApi

        patch do
          authorize! Item, :update
          item = fetch_item! includes: true
          item.cache_previous_version
          item.updater = current_user
          original_title = nil

          Item.transaction do
            %i(startYear endYear numberOfParts).each do |attr|
              item.send "#{attr.to_s.underscore}=".to_sym, params[attr] if params.key? attr
            end
            item.language = language params[:language] if params.key? :language
            set_image! item, params[:image] if params[:image].kind_of? Hash
            item.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != item.tags

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
                item.titles.build(contents: title[:text], language: language(title[:language]), display_position: params[:titles].index(title))
              end
            end

            if params.key? :relationships
              relationships_to_add = params[:relationships]

              item.relationships.each do |relationship|
                if relationship_data = params[:relationships].find{ |r| r[:relation] == relationship.relationship && r[:personId] == relationship.person.api_id }
                  relationships_to_add.delete relationship_data
                else
                  relationship.mark_for_destruction
                end
              end

              relationships_to_add.each do |relationship|
                item.relationships.build(relationship: relationship[:relation], person: Person.where(api_id: relationship[:personId]).first!)
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
                item.links.build(url: link[:url], language: link[:language] ? language(link[:language]) : nil)
              end
            end

            item.save!

            original_title = item.titles.find{ |t| t.display_position == 0 }
            if item.original_title_id != original_title.id
              item.original_title = original_title
              item.update_columns original_title_id: original_title.id
            end
          end

          item.to_builder.attributes!
        end
      end
    end
  end
end
