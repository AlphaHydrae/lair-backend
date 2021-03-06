class Collection < ActiveRecord::Base
  include ResourceWithIdentifier
  include TrackedMutableResource

  before_create :set_identifier
  before_save :normalize_name
  before_save :clean_data
  before_save :update_users
  after_destroy :remove_featured

  belongs_to :user
  has_many :collection_works
  has_many :collection_items
  has_many :collection_ownerships
  has_many :works, through: :collection_works
  has_many :items, class_name: 'Item', through: :collection_items
  has_many :ownerships, through: :collection_ownerships
  has_and_belongs_to_many :users

  strip_attributes
  validates :user, presence: true
  validates :name, presence: true, length: { maximum: 50 }, format: { with: /\A[a-z0-9]+(\-[a-z0-9]+)*\Z/i }, uniqueness: { case_sensitive: false, scope: :user_id }
  validates :display_name, presence: true, length: { maximum: 50 }
  validates :public_access, inclusion: { in: [ true, false ] }
  validates :featured, inclusion: { in: [ true, false ] }
  validate :private_collection_cannot_be_featured

  def apply rel

    # Restrict to the categories indicated by the collection.
    if restrictions['categories'].present?
      rel = rel.where 'works.category IN (?)', restrictions['categories']
    end

    # Restrict to works and items owned by the users indicated by the collection.
    if restrictions['ownerIds'].present?
      rel = rel.where 'ownerships.owned = ? AND users.api_id IN (?)', true, restrictions['ownerIds']
    end

    conditions = []
    values = []

    # Restrict to the works and items linked to the collection.
    if collection_works.present?
      conditions << 'works.id IN (?)'
      values << collection_works.collect(&:work_id)
    end

    # Restrict to the works and items linked to the collection.
    if collection_items.present?
      conditions << 'items.id IN (?)'
      values << collection_items.collect(&:item_id)
    end

    # Restrict to the ownerships linked to the collection.
    if collection_ownerships.present?
      conditions << 'ownerships.id IN (?)'
      values << collection_ownerships.collect(&:ownership_id)
    end

    if conditions.any?
      rel = rel.where *values.unshift(conditions.join(' OR '))
    end

    rel
  end

  def data
    if d = super
      d
    else
      self.data = {}
    end
  end

  def restrictions
    if r = data['restrictions']
      r
    else
      self.data['restrictions'] = {}
    end
  end

  def default_filters
    if r = data['defaultFilters']
      r
    else
      self.data['defaultFilters'] = {}
    end
  end

  private

  def private_collection_cannot_be_featured
    errors.add :public_access, :cannot_be_featured if featured && !public_access
  end

  def normalize_name
    self.normalized_name = name.to_s.downcase
  end

  def clean_data
    self.data.delete 'restrictions' if data['restrictions'].blank?
    self.data.delete 'defaultFilters' if data['defaultFilters'].blank?
  end

  def update_users
    user_ids = []
    user_ids += data['restrictions'].try(:[], 'ownerIds') || []
    user_ids += data['defaultFilters'].try(:[], 'ownerIds') || []
    self.users = User.select('id, roles_mask').where(api_id: user_ids.uniq).to_a
  end

  def remove_featured
    featured_id = $redis.get 'collections:featured'
    $redis.del 'collections:featured' if featured_id == api_id
    true
  end
end
