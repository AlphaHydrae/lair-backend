class WorkPerson < ActiveRecord::Base
  # TODO: rename to WorkRelationship

  belongs_to :work, touch: true
  belongs_to :person

  strip_attributes
  validates :work, presence: true
  validates :person, presence: true
  validates :relation, presence: true, inclusion: { in: %w(actor artist author composer director producer voice_actor writer), allow_blank: true }
  validates :details, length: { maximum: 255 }
  validate :relation_must_be_allowed_for_work_category

  private

  def relation_must_be_allowed_for_work_category
    return if work.blank? || work.category.blank?

    common_video_relations = %w(composer director producer writer)

    if %w(anime).include?(work.category) && !(common_video_relations << 'voice_actor').include?(relation)
      errors.add :relation, :not_allowed_for_category
    elsif %w(movie show).include?(work.category) && !(common_video_relations << 'actor').include?(relation)
      errors.add :relation, :not_allowed_for_category
    elsif %w(book magazine manga).include?(work.category) && !%w(artist author).include?(relation)
      errors.add :relation, :not_allowed_for_category
    end
  end
end
