class Person < ActiveRecord::Base

  strip_attributes
  validates :last_name, absence: { if: :pseudonym? }, presence: { unless: :pseudonym? }, length: { maximum: 255, allow_blank: true }, uniqueness: { scope: %i(first_names pseudonym) }
  validates :first_names, absence: { if: :pseudonym? }, presence: { unless: :pseudonym? }, length: { maximum: 255, allow_blank: true }
  validates :pseudonym, presence: { allow_nil: true }, length: { maximum: 255, allow_blank: true }
  validate :name_present

  def pseudonym?
    pseudonym.present?
  end

  private

  def name_present
    errors.add :base, :name_must_be_present unless pseudonym.present? || last_name.present? || first_names.present?
  end
end
