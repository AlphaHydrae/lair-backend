class MediaSettings < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates :ignores, length: { maximum: 25, too_long: "cannot contain more than %{count} patterns" }
  validate :ignores_should_not_be_too_long

  private

  def ignores_should_not_be_too_long
    errors.add :ignores, :ignore_too_long if ignores.any?{ |ignore| ignore.to_s.length > 50 }
  end
end
