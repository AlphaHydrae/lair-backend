class WorkPerson < ActiveRecord::Base
  # TODO: rename to WorkRelationship

  before_save :normalize_relation

  belongs_to :work, touch: true
  belongs_to :person

  strip_attributes
  validates :work, presence: true
  validates :person, presence: true
  validates :relation, presence: true, length: { maximum: 50 }, uniqueness: { scope: %i(person_id work_id), case_sensitive: false, allow_blank: true }
  validates :details, length: { maximum: 255 }

  private

  def normalize_relation
    self.normalized_relation = relation.to_s.downcase
  end
end
