class WorkCompany < ActiveRecord::Base

  belongs_to :work, touch: true
  belongs_to :company

  strip_attributes
  validates :work, presence: true
  validates :company, presence: true
  validates :relation, presence: true, inclusion: { in: %w(production_company publishing_company), allow_blank: true }
  validates :details, length: { maximum: 255 }
  validate :relation_must_be_allowed_for_work_category

  private

  def relation_must_be_allowed_for_work_category
    return if work.blank? || work.category.blank?

    if %w(anime movie show).include?(work.category) && !%w(production_company).include?(relation)
      errors.add :relation, :not_allowed_for_category
    elsif %w(book magazine manga).include?(work.category) && !%w(publishing_company).include?(relation)
      errors.add :relation, :not_allowed_for_category
    end
  end
end
