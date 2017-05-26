module Lair
  class UsersApi < Grape::API
    namespace :users do
      post do
        authorize! User, :create

        record = User.new name: params[:name].to_s, email: params[:email].to_s, active: !!params[:active]

        if params.key?(:roles) && params[:roles].kind_of?(Array)
          record.roles = params[:roles].collect(&:to_s).collect(&:underscore).uniq.sort
        end

        record.save!
        serialize record
      end

      get do
        authorize! User, :index

        rel = paginated(User) do |rel|

          if params[:name].present?
            rel = rel.where normalized_name: params[:name].to_s.downcase
          end

          if params[:search].present?
            rel = rel.where('normalized_name LIKE ?', "%#{params[:search].to_s.downcase}%")
          end

          rel
        end

        rel = rel.order 'normalized_name ASC'

        serialize load_resources(rel)
      end

      namespace '/:id' do
        helpers do
          def record
            @record ||= load_resource!(User.where(api_id: params[:id].to_s))
          end
        end

        get do
          authorize! User, :show
          serialize record
        end

        patch do
          authorize! User, :update

          User.transaction do
            record.name = params[:name].to_s if params.key? :name

            if params.key? :active
              authorize! User, :update_active
              record.active = !!params[:active]
            end

            if params.key?(:email) && params[:email].to_s != record.email
              authorize! User, :update_email
              record.email = params[:email].to_s
            end

            if params.key?(:roles) && params[:roles].kind_of?(Array)
              roles = params[:roles].collect(&:to_s).uniq.sort
              if roles != record.roles.to_a.collect(&:to_s).sort
                authorize! User, :update_roles
                record.roles = roles
              end
            end

            record.save!
            serialize record
          end
        end
      end
    end
  end
end
