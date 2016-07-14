module Lair
  class MediaFingerprintsApi < Grape::API
    namespace :fingerprints do
      helpers do
        def with_serialization_includes rel
          rel.includes :source, :media_url
        end

        def serialization_options *args
          {}
        end
      end

      get do
        authorize! MediaSource, :index

        rel = policy_scope MediaFingerprint.order('media_fingerprints.created_at DESC')

        rel = paginated rel do |rel|

          media_url_joined = false
          media_url_joins = []

          if params[:category].present?
            media_url_joined = true
            media_url_joins << :work

            rel = rel
              .where('works.category IN (?)', Array.wrap(params[:category]).collect(&:to_s))
          end

          if params[:sourceId].present?
            rel = rel
              .joins(:source)
              .where('media_sources.api_id IN (?)', Array.wrap(params[:sourceId]).collect(&:to_s))
          end

          if params[:mediaUrlId].present?
            media_url_joined = true

            rel = rel
              .where('media_urls.api_id IN (?)', Array.wrap(params[:mediaUrlId]).collect(&:to_s))
          end

          if media_url_joined
            rel = if media_url_joins.present?
              rel.joins media_url: media_url_joins
            else
              rel.joins :media_url
            end
          end

          rel
        end

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(MediaFingerprint.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! record, :show
          serialize record
        end
      end
    end
  end
end
