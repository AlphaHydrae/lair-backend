class AddIssueItemType < ActiveRecord::Migration
  class Work < ActiveRecord::Base; end
  class Item < ActiveRecord::Base; end

  def up
    add_column :items, :issn, :string, limit: 8

    magazines_rel = Work.where category: 'magazine'
    rel = Item.where work_id: magazines_rel, type: 'Volume'
    n = rel.count

    say_with_time "fixing type and ISSN of #{n} magazine issues" do
      rel.where("(properties->>'issn') IS NOT NULL").select(:id, :properties).to_a.each do |issue|
        properties = issue.properties
        if StdNum::ISSN.valid? properties['issn']
          issn = properties.delete 'issn'
          normalized_issn = StdNum::ISSN.normalize(issn).gsub /[^0-9X]+/, ''
          Item.where(id: issue.id).update_all issn: normalized_issn, properties: properties
        else
          raise "ISSN #{properties['issn'].inspect} is not valid!"
        end
      end

      rel.update_all type: 'Issue', version: nil
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
