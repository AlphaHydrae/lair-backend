module Lair
  module MainImageSearchApi
    def self.included base
      base.instance_eval do
        namespace 'main-image-search' do
          get do
            authorize! ImageSearch, :show
            serialize current_imageable.main_image_search!
          end

          patch do
            authorize! ImageSearch, :update
            serialize search_images_for(current_imageable)
          end
        end
      end
    end
  end
end
