module Lair
  class CollectionsApi < Grape::API
    namespace :collections do
      helpers do
        def with_serialization_includes rel
          rel = rel.includes :user
          rel
        end

        def serialization_options *args
          {
            with_links: true_flag?(:withLinks),
            with_user: true_flag?(:withUser)
          }
        end

        def update_record_from_params record
          record.name = params[:name].to_s if params.key? :name
          record.display_name = params[:displayName].to_s if params.key? :displayName
          record.public_access = !!params[:public] if params.key? :public
          record.featured = !!params[:featured] if params.key? :featured

          restrictions = params[:restrictions]
          if restrictions.kind_of? Hash

            categories = restrictions['categories']
            if categories.kind_of? Array
              record.restrictions['categories'] = categories.collect(&:to_s).select(&:present?).uniq
              record.restrictions.delete 'categories' if record.restrictions['categories'].blank?
            else
              record.restrictions.delete 'categories'
            end

            owner_ids = restrictions[:ownerIds]
            if owner_ids.kind_of? Array
              record.restrictions['ownerIds'] = owner_ids.collect(&:to_s).select(&:present?).uniq
              record.restrictions.delete 'ownerIds' if record.restrictions['ownerIds'].blank?
            else
              record.restrictions.delete 'ownerIds'
            end
          end

          default_filters = params[:defaultFilters]
          if default_filters.kind_of? Hash

            search = default_filters['search']
            if search.present?
              record.default_filters['search'] = search
            else
              record.default_filters.delete 'search'
            end

            resource = default_filters['resource']
            if resource.present?
              record.default_filters['resource'] = resource
            else
              record.default_filters.delete 'resource'
            end

            categories = default_filters['categories']
            if categories.kind_of? Array
              record.default_filters['categories'] = categories.collect(&:to_s).select(&:present?).uniq
              record.default_filters.delete 'categories' if record.default_filters['categories'].blank?
            else
              record.default_filters.delete 'categories'
            end

            owner_ids = default_filters[:ownerIds]
            if owner_ids.kind_of? Array
              record.default_filters['ownerIds'] = owner_ids.collect(&:to_s).select(&:present?).uniq
              record.default_filters.delete 'ownerIds' if record.default_filters['ownerIds'].blank?
            else
              record.default_filters.delete 'ownerIds'
            end
          end
        end
      end

      post do
        user = params.key?(:userId) ? User.where(api_id: params[:userId].to_s).first! : current_user
        record = Collection.new creator: current_user, user: user
        authorize! record, :create

        Collection.transaction do
          update_record_from_params record

          record.save!
          serialize record
        end
      end

      get do
        authorize! Collection, :index

        rel = policy_scope(Collection)

        rel = paginated rel do |rel|

          if params[:userId].present?
            user = User.where(api_id: params[:userId].to_s).first!
            rel = rel.where user_id: user.id
          end

          if params[:userName].present?
            user = User.where(normalized_name: params[:userName].to_s.downcase).first!
            rel = rel.where user_id: user.id
          end

          if params[:name].present?
            rel = rel.where normalized_name: params[:name].to_s.downcase
          end

          if params.key? :public
            rel = rel.where public_access: true_flag?(:public)
          end

          if params.key? :featured
            if params[:featured] == 'daily'
              featured_id = $redis.get 'collections:featured'

              unless featured_id
                featured = Collection.where(featured: true).order('RANDOM()').limit(1).first
                $redis.set 'collections:featured', featured.api_id, ex: 1.day.to_i, nx: true if featured.present?
                featured_id = featured.try :api_id
              end

              if featured_id.present?
                rel = rel.where api_id: featured_id
              else
                rel = rel.none
              end
            else
              rel = rel.where featured: true_flag?(:featured)
            end
          end

          rel
        end

        if true_flag? :random
          rel = rel.order 'RANDOM()'
        else
          rel = rel.order 'name ASC, created_at ASC'
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(Collection.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end

        patch do
          authorize! record, :update

          Collection.transaction do
            record.cache_previous_version
            record.updater = current_user
            update_record_from_params record

            record.save!
            serialize record
          end
        end

        delete do
          authorize! record, :destroy
          record.deleter = current_user
          record.cache_previous_version
          record.destroy
          status 204
          nil
        end

        namespace do
          helpers do
            def with_serialization_includes rel
              rel
            end

            def serialization_options *args
              {}
            end
          end

          namespace :works do
            helpers do
              def collection_link_model
                CollectionWork
              end

              def collection_link_target_model
                Work
              end
            end

            include CollectionLinksApi
          end

          namespace :items do
            helpers do
              def collection_link_model
                CollectionItem
              end

              def collection_link_target_model
                Item
              end
            end

            include CollectionLinksApi
          end

          namespace :ownerships do
            helpers do
              def collection_link_model
                CollectionOwnership
              end

              def collection_link_target_model
                Ownership
              end
            end

            include CollectionLinksApi
          end
        end
      end
    end
  end
end
