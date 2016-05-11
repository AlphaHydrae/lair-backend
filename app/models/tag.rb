class Tag < ActiveRecord::Base
  before_create :normalize_name

  has_and_belongs_to_many :works

  validates :name, presence: true, uniqueness: { case_sensitive: false, allow_blank: true }

  private

  def normalize_name
    self.normalized_name = name.to_s.downcase
  end
end
