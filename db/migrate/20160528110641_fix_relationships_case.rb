class FixRelationshipsCase < ActiveRecord::Migration
  class WorkPerson < ActiveRecord::Base; end
  class WorkCompany < ActiveRecord::Base; end

  def up
    work_people_rel = WorkPerson.where 'LOWER(relation) = relation'
    work_companies_rel = WorkCompany.where 'LOWER(relation) = relation'

    say_with_time "updating relation of #{work_people_rel.count} work people and #{work_companies_rel.count} work companies" do
      work_people_rel.find_each do |wp|
        wp.update_columns relation: wp.relation.humanize, normalized_relation: wp.relation.downcase
      end

      work_companies_rel.find_each do |wc|
        wc.update_columns relation: wc.relation.humanize, normalized_relation: wc.relation.downcase
      end
    end
  end

  def down
    # nothing to do
  end
end
