module Lair
  class MediaUrlsApi < Grape::API
    namespace :urls do
      helpers do
        def serialization_options *args
          {
            include_scrap: include_in_response?(:scrap),
            include_work: include_in_response?(:work)
          }
        end

        def with_serialization_includes rel
          rel = rel.includes(:work, { scrap: :media_url })
          rel
        end

        def update_record_from_params record
          %i(provider category providerId).each do |attr|
            record.send "#{attr.to_s.underscore}=", params[attr]
          end
        end
      end

      post do
        media_url = MediaUrl.new creator: current_user
        update_record_from_params media_url

        authorize! media_url, :create

        MediaUrl.transaction do
          media_url.save!
          serialize media_url
        end
      end

      get do
        authorize! MediaUrl, :index

        rel = policy_scope MediaUrl.order('media_urls.provider ASC, media_urls.category ASC, media_urls.provider_id ASC')

        rel = paginated rel do |rel|

          rel = rel.joins :scrap if params[:scrapStates].present? || params[:scrapWarnings].present?

          if params[:scrapStates].present?
            states = Array.wrap(params[:scrapStates]).collect(&:to_s).collect &:underscore
            rel = rel.where 'media_scraps.state IN (?)', states
          end

          if true_flag? :scrapWarnings
            rel = rel.where 'media_scraps.warnings_count >= 1'
          elsif false_flag? :scrapWarnings
            rel = rel.where 'media_scraps.warnings_count <= 0'
          end

          rel
        end

        serialize load_resources(rel)
      end
    end

    namespace :urlResolution do
      post do
        authorize! MediaUrl, :resolve

        url = params[:url].to_s
        media_url = MediaUrl.resolve url: url

        if media_url.blank?
          return {
            url: url,
            resolved: false
          }
        end

        serialize(media_url).merge resolved: true
      end
    end
  end
end
