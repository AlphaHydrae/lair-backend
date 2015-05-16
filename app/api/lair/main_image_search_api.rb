module Lair
  module MainImageSearchApi
    def self.included base
      base.instance_eval do
        namespace 'main-image-search' do
          get do
            authorize! ImageSearch, :show
            current_imageable.main_image_search!.to_builder.attributes!
          end

          patch do
            authorize! ImageSearch, :update
            search_images_for(current_imageable).to_builder.attributes!
          end
        end
      end
    end
  end
end
