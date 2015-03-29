module Lair
  class OwnershipsApi < Grape::API
    namespace :ownerships do
      post do
        authenticate!

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

          ownership.to_builder(options).attributes!
        end
      end

      get do
        authenticate!

        rel = Ownership.joins(:item_part).joins(:user).order('item_parts.effective_title ASC, users.email ASC')

        relation = paginated rel do |rel|

          item_part_joined = false
          if params[:partId].present?
            item_part_joined = true
            rel = rel.joins(:item_part).where item_parts: { api_id: params[:partId].to_s }
          end

          user_joined = false
          if params[:userId].present?
            user_joined = true
            rel = rel.joins(:user).where users: { api_id: params[:userId].to_s }
          end

          if params[:search].present?
            rel = rel.joins :item_part unless item_part_joined
            rel = rel.joins :user unless user_joined
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

        relation.includes(includes).to_a.collect{ |o| o.to_builder(options).attributes! }
      end

      namespace '/:ownershipId' do

        helpers do
          def fetch_ownership!
            Ownership.where(api_id: params[:ownershipId]).first!
          end
        end

        patch do
          authenticate!
          ownership = fetch_ownership!
          ownership.cache_previous_version
          ownership.updater = current_user

          ownership.item_part = ItemPart.where(api_id: params[:partId]).first! if params.key? :partId
          ownership.user = User.where(api_id: params[:userId]).first! if params.key? :userId
          ownership.tags = params[:tags].select{ |k,v| v.kind_of? String } if params[:tags].kind_of?(Hash) && params[:tags] != ownership.tags
          ownership.gotten_at = Time.parse params[:gottenAt] if params.key? :gottenAt
          ownership.save!

          options = {
            with_part: true_flag?(:withPart),
            with_user: true_flag?(:withUser)
          }

          ownership.to_builder(options).attributes!
        end

        delete do
          authenticate!

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
