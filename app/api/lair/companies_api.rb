module Lair
  class CompaniesApi < Grape::API
    namespace :companies do
      post do
        authorize! Company, :create

        company = Company.new creator: current_user
        company.name = params[:name].to_s

        company.save!
        serialize company
      end

      get do
        authorize! Company, :index

        rel = Company.order 'name ASC'

        rel = paginated rel do |rel|

          if params[:name].present?
            rel = rel.where 'LOWER(companies.name) = ?', params[:name].to_s.downcase
          elsif params.key? :name
            rel = rel.where 'companies.name IS NULL'
          end

          if params[:search].present?
            base_condition = 'LOWER(companies.name) LIKE ?'
            terms = params[:search].to_s.downcase.split(/\s+/)
            condition = ([ base_condition ] * terms.length).join ' '
            rel = rel.where terms.inject([]){ |memo,t| memo << t }.collect{ |t| "%#{t}%" }.unshift(condition)
          end

          rel
        end

        serialize load_resources(rel)
      end
    end
  end
end
