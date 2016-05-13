class User < ActiveRecord::Base
  include RoleModel
  include ResourceWithIdentifier

  before_create :set_identifier
  before_save :normalize_name
  # TODO: add tracking information about logins

  roles :admin

  strip_attributes
  validates :name, presence: true, length: { maximum: 25 }, format: { with: /\A[a-z0-9]+(\-[a-z0-9]+)*\Z/i }, uniqueness: { case_sensitive: false }
  validates :email, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false }

  def active?
    active
  end

  def email= value
    write_attribute :email, value.try(:downcase)
  end

  private

  def normalize_name
    self.normalized_name = name.downcase
  end
end
