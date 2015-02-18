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

        part = ItemPart.where(api_id: params[:partId]).first!
        user = params.key?(:userId) ? User.where(api_id: params[:userId]).first! : current_user

        Ownership.transaction do
          ownership = Ownership.new item_part: part, user: user
          ownership.gotten_at = Time.parse params[:gottenAt] if params[:gottenAt]
          ownership.save!
          ownership.to_builder.attributes!
        end
      end
    end

    namespace :people do
      post do
        authenticate!

        person = Person.new
        %i(last_name first_names pseudonym).each{ |attr| person.send "#{attr}=", params[attr.to_s.camelize(:lower)] if params.key? attr.to_s.camelize(:lower) }

        person.save!
        person.to_builder.attributes!
      end

      get do
        authenticate!

        limit = params[:pageSize].to_i
        limit = 10 if limit < 1

        page = params[:page].to_i
        offset = (page - 1) * limit
        if offset < 1
          page = 1
          offset = 0
        end

        header 'X-Pagination-Page', page.to_s
        header 'X-Pagination-Page-Size', limit.to_s
        header 'X-Pagination-Total', Person.count.to_s

        rel = Person.order('last_name, first_names, pseudonym').offset(offset).limit(limit)

        if params[:search].present?
          base_condition = 'LOWER(people.last_name) LIKE ? OR LOWER(people.first_names) LIKE ? OR LOWER(people.pseudonym) LIKE ?'
          terms = params[:search].to_s.split(/\s+/)
          condition = ([ base_condition ] * terms.length).join ' '
          rel = rel.where terms.inject([]){ |memo,t| memo << t << t << t }.collect{ |t| "%#{t}%" }.unshift(condition)
          header 'X-Pagination-Filtered-Total', rel.count.to_s
        end

        rel.all.to_a.collect{ |person| person.to_builder.attributes! }
      end
    end

    get :bookPublishers do
      authenticate!
      Book.order(:publisher).pluck('distinct(publisher)').compact.collect{ |publisher| { name: publisher } }
    end

    get :partEditions do
      authenticate!
      ItemPart.order(:edition).pluck('distinct(edition)').compact.collect{ |edition| { name: edition } }
    end

    get :partFormats do
      authenticate!
      ItemPart.order(:format).pluck('distinct(format)').compact.collect{ |format| { name: format } }
    end

    namespace :parts do
      post do
        authenticate!

        item = Item.where(api_id: params[:itemId]).first!
        language = language(params[:language])

        part = Book.new

        # TODO: update item number of parts & year if applicable

        ItemPart.transaction do
          part.item = item
          part.title = item.titles.where(api_id: params[:title][:id]).first! if params[:title].kind_of?(Hash) && params[:title].key?(:id)
          part.custom_title = params[:title][:text] if params[:title].kind_of?(Hash) && !params[:title].key?(:id) && params[:title].key?(:text)
          part.custom_title_language = language params[:title][:language] if params[:title].kind_of?(Hash) && !params[:title].key?(:id) && params[:title].key?(:language)
          part.language = language
          part.year = params[:year] if params.key?(:year)
          part.range_start = params[:start] if params.key?(:start)
          part.range_end = params[:end] if params.key?(:end)
          part.edition = params[:edition]
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

      get do
        item = Item.where(api_id: params[:itemId]).first!
        ItemPart.joins(:item).where('items.id = ?', item.id).order('item_parts.range_start asc').includes(:title, :language).all.to_a.collect{ |item| item.to_builder.attributes! }
      end

      namespace '/:partId' do

        helpers do
          def fetch_part
            ItemPart.where(api_id: params[:partId]).includes([ :title, :language ]).first!
          end
        end

        get do
          fetch_part.to_builder.attributes!
        end

        patch do
          authenticate!
          part = fetch_part

          ItemPart.transaction do
            part.item = Item.where(api_id: params[:itemId]).first! if params.key? :itemId
            part.title = part.item.titles.where(api_id: params[:titleId]).first! if params[:title].kind_of?(Hash) && params[:title].key?(:id)
            part.custom_title = params[:title][:text] if params[:title].kind_of?(Hash) && !params[:title].key?(:id) && params[:title].key?(:text)
            part.custom_title_language = language params[:title][:language] if params[:title].kind_of?(Hash) && !params[:title].key?(:id) && params[:title].key?(:language)
            part.language = language params[:language] if params.key? :language
            part.range_start = params[:start] if params.key? :start
            part.range_end = params[:end] if params.key? :end
            %i(year edition version format length publisher isbn).each do |attr|
              part.send "#{attr}=", params[attr] if params.key? attr
            end
            part.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != part.tags
            part.save!
          end

          part.to_builder.attributes!
        end
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

          item.original_title = item.titles.first
          item.save!

          item.to_builder.attributes!
        end
      end

      get do
        limit = params[:pageSize].to_i
        limit = 10 if limit < 1

        page = params[:page].to_i
        offset = (page - 1) * limit
        if offset < 1
          page = 1
          offset = 0
        end

        header 'X-Pagination-Page', page.to_s
        header 'X-Pagination-Page-Size', limit.to_s
        header 'X-Pagination-Total', Item.count.to_s

        rel = Item.joins('INNER JOIN item_titles AS original_titles ON original_titles.id = items.original_title_id').order('original_titles.contents asc').offset(offset).limit(limit).includes([ :language, :links, { titles: :language } ])

        if params[:search].present?
          rel = rel.joins(:titles).where 'LOWER(item_titles.contents) LIKE ?', "%#{params[:search].to_s.downcase}%"
          header 'X-Pagination-Filtered-Total', rel.count.to_s
        end

        rel.all.to_a.collect{ |item| item.to_builder.attributes! }
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
          authenticate!
          item = fetch_item

          Item.transaction do
            %i(startYear endYear numberOfParts).each do |attr|
              item.send "#{attr.to_s.underscore}=".to_sym, params[attr] if params.key? attr
            end
            item.language = language params[:language] if params.key? :language
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

            # FIXME: update original title
            item.save!
          end

          item.to_builder.attributes!
        end
      end
    end
  end
end
