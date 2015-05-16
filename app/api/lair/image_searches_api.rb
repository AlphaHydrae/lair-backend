module Lair
  module ImageSearchesApi
    def self.included base
      base.instance_eval do
        namespace 'image-searches' do
          get do
            authorize! ImageSearch, :index
            rel = ImageSearch
            rel = rel.where imageable: current_imageable if respond_to? :current_imageable
            paginated(rel).to_a.collect{ |search| search.to_builder.attributes! }
          end

          post do
            authorize! ImageSearch, :create
            if respond_to? :current_imageable
              search_images_for(current_imageable, force: true).to_builder.attributes!
            else
              search_images.to_builder.attributes!
            end
          end
        end
      end
    end
  end
end
