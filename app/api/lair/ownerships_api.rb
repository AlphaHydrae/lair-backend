module Lair
  class OwnershipsApi < Grape::API
    namespace :ownerships do
      post do
        item = Item.where(api_id: params[:itemId]).first!
        user = params.key?(:userId) ? User.where(api_id: params[:userId]).first! : current_user
        ownership = Ownership.new item: item, user: user, creator: current_user

        authorize! ownership, :create

        Ownership.transaction do
          ownership.set_properties_from_params params[:properties]
          ownership.gotten_at = Time.parse params[:gottenAt] if params[:gottenAt]
          ownership.save!

          options = {
            with_item: true_flag?(:withItem),
            with_user: true_flag?(:withUser)
          }

          serialize ownership, options
        end
      end

      get do
        authorize! Ownership, :index

        rel = Ownership.joins(item: :work).joins(:user).order('items.sortable_title ASC, users.normalized_name ASC, gotten_at DESC')

        relation = paginated rel do |rel|

          if params[:categories].present?
            rel = rel.where 'works.category IN (?)', Array.wrap(params[:categories]).collect(&:to_s).select(&:present?)
          end

          if params[:ownerIds].present?
            rel = rel.where 'ownerships.owned = ? AND users.api_id IN (?)', true, Array.wrap(params[:ownerIds]).collect(&:to_s)
          end

          if params[:collectionId].present?
            collection = Collection.where(api_id: params[:collectionId].to_s).first!
            rel = collection.apply rel
          end

          if params[:itemId].present?
            rel = rel.where items: { api_id: params[:itemId].to_s }
          end

          if params[:itemIds].kind_of? Array
            rel = rel.where 'items.api_id IN (?)', params[:itemIds].collect(&:to_s).select(&:present?).uniq
          end

          if params[:userId].present?
            rel = rel.where users: { api_id: params[:userId].to_s }
          end

          if params.key? :owned
            rel = rel.where 'ownerships.owned = ?', true_flag?(:owned)
          end

          if params[:search].present?
            term = "%#{params[:search].downcase}%"
            rel = rel.where 'LOWER(items.sortable_title) LIKE ? OR LOWER(users.email) LIKE ?', term, term
          end

          rel
        end

        options = {
          with_item: true_flag?(:withItem),
          with_user: true_flag?(:withUser)
        }

        includes = []
        includes << :user if options[:with_user]
        includes << { item: [ :work, { titles: :language, work_title: :language }, :language ] } if options[:with_item]

        resources = load_resources relation.preload(includes)

        if options[:with_item] && current_user
          options[:ownerships] = Ownership.joins(:item).where(items: { id: resources.collect(&:item_id) }, ownerships: { user_id: current_user.id }).to_a
        end

        serialize resources, options
      end

      namespace '/:ownershipId' do

        helpers do
          def record
            @record ||= Ownership.where(api_id: params[:ownershipId]).first!
          end
        end

        patch do
          authorize! record, :update

          record.cache_previous_version
          record.updater = current_user

          if params.key?(:userId) && params[:userId].to_s != record.user.api_id
            authorize! record, :update_user
            record.user = User.where(api_id: params[:userId].to_s).first!
          end

          record.item = Item.where(api_id: params[:itemId]).first! if params.key? :itemId
          record.set_properties_from_params params[:properties]
          record.gotten_at = Time.parse params[:gottenAt] if params.key? :gottenAt
          record.yielded_at = Time.parse params[:yieldedAt] if params.key? :yieldedAt
          record.save!

          options = {
            with_item: true_flag?(:withItem),
            with_user: true_flag?(:withUser)
          }

          serialize record, options
        end

        delete do
          authorize! record, :destroy

          record.cache_previous_version
          record.deleter = current_user
          record.destroy

          status 204
          nil
        end
      end
    end
  end
end
