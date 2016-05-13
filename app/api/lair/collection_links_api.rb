module Lair
  module CollectionLinksApi
    def self.included base
      base.instance_eval do
        helpers do
          def collection_link_target_association_name
            collection_link_target_model.name.underscore.to_sym
          end
        end

        post do
          authorize! record, :update

          collection_link_model.transaction do
            link_record = collection_link_model.new
            link_record.collection = record
            link_record.send "#{collection_link_target_association_name}=", collection_link_target_model.where(api_id: params[collection_link_target_association_name.to_s.camelize(:lower) + 'Id'].to_s).first!
            link_record.save!
            serialize link_record
          end
        end

        get do
          authorize! record, :show

          rel = record.send collection_link_model.name.underscore.pluralize
          puts rel.inspect

          rel = paginated rel do
            # nothing to do
            rel
          end

          rel = rel.includes :collection
          rel = rel.includes collection_link_target_association_name

          serialize load_resources(rel)
        end

        namespace '/:subId' do
          helpers do
            def subrecord
              @subrecord ||= load_resource!(record.send(collection_link_model.name.underscore.pluralize).where(api_id: params[:subId].to_s))
            end
          end

          delete do
            authorize! record, :update
            subrecord.destroy
            status 204
            nil
          end
        end
      end
    end
  end
end
