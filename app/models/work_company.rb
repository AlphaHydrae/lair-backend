class WorkCompany < ActiveRecord::Base

  before_save :normalize_relation

  belongs_to :work, touch: true
  belongs_to :company

  strip_attributes
  validates :work, presence: true
  validates :company, presence: true
  validates :relation, presence: true, length: { maximum: 50 }, uniqueness: { scope: %i(work_id company_id), case_sensitive: false }
  validates :details, length: { maximum: 255 }

  private

  def normalize_relation
    self.normalized_relation = relation.to_s.downcase
  end
end
