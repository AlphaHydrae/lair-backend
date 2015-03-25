class Person < ActiveRecord::Base
  include ResourceWithIdentifier
  include TrackedMutableResource
  before_create :set_identifier

  strip_attributes
  validates :last_name, presence: { if: ->(p){ p.first_names.present? || p.pseudonym.blank? } }, length: { maximum: 50, allow_blank: true }, uniqueness: { scope: %i(first_names pseudonym) }
  validates :first_names, presence: { if: ->(p){ p.last_name.present? || p.pseudonym.blank? } }, length: { maximum: 100, allow_blank: true }
  validates :pseudonym, presence: { allow_nil: true }, length: { maximum: 50, allow_blank: true }
  validate :name_present

  def pseudonym?
    pseudonym.present?
  end

  def to_builder
    Jbuilder.new do |json|
      json.id api_id
      json.lastName last_name if last_name.present?
      json.firstNames first_names if first_names.present?
      json.pseudonym pseudonym if pseudonym.present?
    end
  end

  private

  def name_present
    errors.add :base, :name_must_be_present unless pseudonym.present? || last_name.present? || first_names.present?
  end
end
