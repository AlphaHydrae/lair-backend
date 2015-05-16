module Lair
  class PeopleApi < Grape::API
    namespace :people do
      post do
        authorize! Person, :create

        person = Person.new creator: current_user
        %i(last_name first_names pseudonym).each{ |attr| person.send "#{attr}=", params[attr.to_s.camelize(:lower)] if params.key? attr.to_s.camelize(:lower) }

        person.save!
        person.to_builder.attributes!
      end

      get do
        authorize! Person, :index

        limit = params[:pageSize].to_i
        limit = 10 if limit < 1

        page = params[:page].to_i
        offset = (page - 1) * limit
        if offset < 1
          page = 1
          offset = 0
        end

        header 'X-Pagination-Page', page.to_s
        header 'X-Pagination-PageSize', limit.to_s
        header 'X-Pagination-Total', Person.count.to_s

        rel = Person.order('last_name, first_names, pseudonym').offset(offset).limit(limit)

        if params[:firstNames].present?
          rel = rel.where 'LOWER(people.first_names) = ?', params[:firstNames].to_s.downcase
        elsif params.key? :firstNames
          rel = rel.where 'people.first_names IS NULL'
        end

        if params[:lastName].present?
          rel = rel.where 'LOWER(people.last_name) = ?', params[:lastName].to_s.downcase
        elsif params.key? :lastName
          rel = rel.where 'people.last_name IS NULL'
        end

        if params[:pseudonym].present?
          rel = rel.where 'LOWER(people.pseudonym) = ?', params[:pseudonym].to_s.downcase
        elsif params.key? :pseudonym
          rel = rel.where 'people.pseudonym IS NULL'
        end

        if params[:search].present?
          base_condition = 'LOWER(people.last_name) LIKE ? OR LOWER(people.first_names) LIKE ? OR LOWER(people.pseudonym) LIKE ?'
          terms = params[:search].to_s.downcase.split(/\s+/)
          condition = ([ base_condition ] * terms.length).join ' '
          rel = rel.where terms.inject([]){ |memo,t| memo << t << t << t }.collect{ |t| "%#{t}%" }.unshift(condition)
          header 'X-Pagination-FilteredTotal', rel.count.to_s
        end

        rel.all.to_a.collect{ |person| person.to_builder.attributes! }
      end
    end
  end
end
