module Lair
  module MainImageSearchApi
    def self.included base
      base.instance_eval do
        namespace 'main-image-search' do
          get do
            authenticate!
            current_imageable.last_image_search!.to_builder.attributes!
          end

          patch do
            authenticate!
            search_images_for(current_imageable).to_builder.attributes!
          end
        end
      end
    end
  end
end
