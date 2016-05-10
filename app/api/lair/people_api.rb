module Lair
  class PeopleApi < Grape::API
    namespace :people do
      post do
        authorize! Person, :create

        person = Person.new creator: current_user
        %i(last_name first_names pseudonym).each{ |attr| person.send "#{attr}=", params[attr.to_s.camelize(:lower)] if params.key? attr.to_s.camelize(:lower) }

        person.save!
        serialize person
      end

      get do
        authorize! Person, :index

        rel = Person.order 'last_name, first_names, pseudonym'

        rel = paginated rel do |rel|

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
          end

          rel
        end

        serialize load_resources(rel)
      end
    end

    namespace :personRelations do
      get do
        authorize! Person, :index

        rel = WorkPerson.select('relation').order('relation')

        @pagination_total_count = rel.count 'distinct relation'

        rel = paginated rel do |rel|

          @pagination_filtered_count = rel.count 'distinct relation'

          rel
        end

        rel = rel.group 'relation'

        rel.to_a.map do |wp|
          {
            relation: wp.relation
          }
        end
      end
    end
  end
end
