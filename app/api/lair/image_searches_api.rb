module Lair
  module ImageSearchesApi
    def self.included base
      base.instance_eval do
        namespace 'image-searches' do
          get do
            authorize! ImageSearch, :index
            rel = ImageSearch
            rel = rel.where imageable: current_imageable if respond_to? :current_imageable
            rel = paginated rel
            serialize load_resources(rel)
          end

          post do
            authorize! ImageSearch, :create
            if respond_to? :current_imageable
              serialize search_images_for(current_imageable, force: true)
            else
              serialize search_images
            end
          end
        end
      end
    end
  end
end
