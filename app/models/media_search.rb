class MediaSearch < ActiveRecord::Base
  include ResourceWithIdentifier

  before_create :set_identifier

  belongs_to :user

  validates :query, presence: true, length: { maximum: 255 }
  validates :provider, presence: true, inclusion: { in: MediaUrl::PROVIDERS.collect(&:to_s), allow_blank: true }
  validates :results, presence: { if: :selected }
  validates :selected, numericality: { only_integer: true, minimum: 0, allow_blank: true }
  validate :selected_must_not_be_greater_than_results_count

  def results= value
    super value
    self.results_count = value.try :length
  end

  private

  def selected_must_not_be_greater_than_results_count
    errors.add :selected, :out_of_bounds if selected.present? && results_count.present? && selected >= results_count
  end
end
