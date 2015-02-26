module Lair
  module ImageSearchesApi
    def self.included base
      base.instance_eval do
        namespace 'image-searches' do
          get do
            authenticate!

            rel = ImageSearch
            rel = rel.where imageable: current_imageable if respond_to? :current_imageable

            paginated(rel).to_a.collect{ |search| search.to_builder.attributes! }
          end

          post do
            authenticate!
            search_images_for(current_imageable, force: true).to_builder.attributes!
          end
        end
      end
    end
  end
end
