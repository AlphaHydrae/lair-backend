module Lair
  class OwnershipsApi < Grape::API
    namespace :ownerships do
      post do
        authorize! Ownership, :create

        part = ItemPart.where(api_id: params[:partId]).first!
        user = params.key?(:userId) ? User.where(api_id: params[:userId]).first! : current_user

        Ownership.transaction do
          ownership = Ownership.new item_part: part, user: user, creator: current_user
          ownership.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != ownership.tags
          ownership.gotten_at = Time.parse params[:gottenAt] if params[:gottenAt]
          ownership.save!

          options = {
            with_part: true_flag?(:withPart),
            with_user: true_flag?(:withUser)
          }

          serialize ownership, options
        end
      end

      get do
        authorize! Ownership, :index

        rel = Ownership.joins(item_part: :item).joins(:user).order('item_parts.effective_title ASC, users.normalized_name ASC, gotten_at DESC')

        relation = paginated rel do |rel|

          if params[:categories].present?
            rel = rel.where 'items.category IN (?)', Array.wrap(params[:categories]).collect(&:to_s).select(&:present?)
          end

          if params[:ownerIds].present?
            rel = rel.where 'ownerships.owned = ? AND users.api_id IN (?)', true, Array.wrap(params[:ownerIds]).collect(&:to_s)
          end

          if params[:collectionId].present?
            collection = Collection.where(api_id: params[:collectionId].to_s).first!
            rel = collection.apply rel
          end

          if params[:partId].present?
            rel = rel.where item_parts: { api_id: params[:partId].to_s }
          end

          if params[:partIds].kind_of? Array
            rel = rel.where 'item_parts.api_id IN (?)', params[:partIds].collect(&:to_s).select(&:present?).uniq
          end

          if params[:userId].present?
            rel = rel.where users: { api_id: params[:userId].to_s }
          end

          if params.key? :owned
            rel = rel.where 'ownerships.owned = ?', true_flag?(:owned)
          end

          if params[:search].present?
            term = "%#{params[:search].downcase}%"
            rel = rel.where 'LOWER(item_parts.effective_title) LIKE ? OR LOWER(users.email) LIKE ?', term, term
          end

          rel
        end

        options = {
          with_part: true_flag?(:withPart),
          with_user: true_flag?(:withUser)
        }

        includes = []
        includes << :user if options[:with_user]
        includes << { item_part: [ :item, { title: :language }, :language, :custom_title_language ] } if options[:with_part]

        resources = load_resources relation.preload(includes)

        if options[:with_part] && current_user
          options[:ownerships] = Ownership.joins(:item_part).where(item_parts: { id: resources.collect(&:item_part_id) }, ownerships: { user_id: current_user.id }).to_a
        end

        serialize resources, options
      end

      namespace '/:ownershipId' do

        helpers do
          def fetch_ownership!
            Ownership.where(api_id: params[:ownershipId]).first!
          end
        end

        patch do
          authorize! Ownership, :update

          ownership = fetch_ownership!
          ownership.cache_previous_version
          ownership.updater = current_user

          ownership.item_part = ItemPart.where(api_id: params[:partId]).first! if params.key? :partId
          ownership.user = User.where(api_id: params[:userId]).first! if params.key? :userId
          ownership.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != ownership.tags
          ownership.gotten_at = Time.parse params[:gottenAt] if params.key? :gottenAt
          ownership.yielded_at = Time.parse params[:yieldedAt] if params.key? :yieldedAt
          ownership.save!

          options = {
            with_part: true_flag?(:withPart),
            with_user: true_flag?(:withUser)
          }

          serialize ownership, options
        end

        delete do
          authorize! Ownership, :destroy

          ownership = fetch_ownership!
          ownership.cache_previous_version
          ownership.deleter = current_user
          ownership.destroy

          status 204
          nil
        end
      end
    end
  end
end
