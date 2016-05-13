module Lair
  class ImageSearchesApi < Grape::API
    namespace :imageSearches do
      helpers do
        def set_image_search_rate_limit_headers rate_limit
          header 'X-RateLimit-Total', rate_limit.total.to_s
          header 'X-RateLimit-Remaining', rate_limit.remaining.to_s
          header 'X-RateLimit-Reset', rate_limit.reset_time.to_i.to_s
        end

        def serialization_options *args
          {
            with_results: true_flag?(:withResults)
          }
        end
      end

      get do
        authorize! ImageSearch, :index

        rel = ImageSearch.order 'created_at DESC'

        rel = paginated rel do
          if params[:resource].present?
            model = resource_name_to_model params[:resource]

            if model.blank?
              rel = rel.none
            else
              if params[:resourceId].present?
                imageable = model.where(api_id: params[:resourceId].to_s).first
                rel = imageable.present? ? rel.where(imageable: imageable) : rel.none
              else
                rel = rel.where 'imageable_type = ?', model.name
              end
            end
          end

          rel
        end

        serialize load_resources(rel)
      end

      post do
        authorize! ImageSearch, :create

        search = ImageSearch.new user: current_user

        if params[:resource].present? || params[:resourceId].present?
          raise 'Only works and items can have an image' unless %w(works items).include? params[:resource].to_s
          search.imageable = resource_name_to_model(params[:resource]).where(api_id: params[:resourceId].to_s).first!
          search.query = search.imageable.default_image_search_query
        end

        search.query = params[:query].to_s if params.key? :query
        raise 'Query is required' unless search.query.present?

        search.engine = 'bingSearch'
        search.engine = params[:engine].to_s if params.key? :engine

        Search.engine(params[:engine]).images! search

        search.save! unless search.rate_limit.exceeded?
        search.rate_limit.enforce! if search.results.nil?
        set_image_search_rate_limit_headers search.rate_limit

        serialize search
      end
    end
  end
end
