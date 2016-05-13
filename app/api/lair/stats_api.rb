module Lair
  class StatsApi < Grape::API
    namespace :stats do
      get :images do
        authorize! :stats, :images

        {
          total: Image.count,
          totalSize: Image.sum(:size),
          thumbnailsSize: Image.sum(:thumbnail_size),
          uploaded: Image.linked.where(state: 'uploaded').count,
          uploading: Image.linked.where(state: %w(created uploading)).count,
          uploadErrors: Image.linked.where(state: 'upload_failed').count,
          orphaned: Image.orphaned.count
        }
      end
    end
  end
end
