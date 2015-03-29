module Lair
  class UsersApi < Grape::API
    namespace :users do
      get do
        relation = paginated(User) do |rel|
          rel = rel.where('email LIKE ?', "%#{params[:search].to_s.downcase}%") if params[:search].present?
          rel
        end

        relation.order('email ASC').to_a.collect{ |u| u.to_builder.attributes! }
      end
    end
  end
end
