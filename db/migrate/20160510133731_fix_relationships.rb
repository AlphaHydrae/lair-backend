class FixRelationships < ActiveRecord::Migration
  class WorkPerson < ActiveRecord::Base; end

  def up
    remove_index :work_people, %i(work_id person_id)
    remove_index :work_companies, %i(work_id company_id)

    change_column :work_people, :relation, :string, null: false, limit: 50
    change_column :work_companies, :relation, :string, null: false, limit: 50

    add_column :work_people, :normalized_relation, :string, limit: 50
    add_column :work_companies, :normalized_relation, :string, limit: 50

    WorkPerson.find_each do |wp|
      wp.update_columns relation: wp.relation.humanize, normalized_relation: wp.relation.downcase
    end

    WorkCompany.find_each do |wc|
      wc.update_columns relation: wc.relation.humanize, normalized_relation: wc.relation.downcase
    end

    change_column :work_people, :normalized_relation, :string, null: false, limit: 50
    change_column :work_companies, :normalized_relation, :string, null: false, limit: 50

    add_index :work_people, %i(work_id person_id normalized_relation), name: :index_work_people_on_work_person_and_relation
    add_index :work_companies, %i(work_id company_id normalized_relation), name: :index_work_companies_on_work_company_and_relation

    change_column :people, :creator_id, :integer, null: true
    change_column :people, :updater_id, :integer, null: true
  end

  def down
    change_column :people, :updater_id, :integer, null: false
    change_column :people, :creator_id, :integer, null: false

    remove_index :work_people, name: :index_work_people_on_work_person_and_relation
    remove_index :work_companies, name: :index_work_companies_on_work_company_and_relation

    remove_column :work_people, :normalized_relation
    remove_column :work_companies, :normalized_relation

    change_column :work_people, :relation, :string, null: false, limit: 20
    change_column :work_companies, :relation, :string, null: false, limit: 20

    WorkPerson.update_all 'relation = LOWER(relation)'
    WorkCompany.update_all 'relation = LOWER(relation)'

    add_index :work_people, %i(work_id person_id), unique: true
    add_index :work_companies, %i(work_id company_id), unique: true
  end
end
