class Language < ActiveRecord::Base

  def self.full_list

    list = all.to_a
    codes = list.inject([]){ |memo,l| memo << l.tag }

    ISO::Language.all.each do |l|
      list << Language.new(tag: l.code) unless codes.include? l.code
    end

    list.sort do |a,b|
      if a.used? ^ b.used?
        a.used? ? -1 : 1
      else
        a.tag <=> b.tag
      end
    end
  end

  strip_attributes
  validates :tag, presence: true, uniqueness: true, format: { with: /\A[a-z]{2}(?:\-[A-Z]{2})?\Z/, allow_blank: true }
  validate :tag_must_be_valid

  def name
    subtags = ISO::Tag.new(tag).subtags
    subtags.length == 1 ? subtags.first.name : "#{subtags[0].name} (#{subtags[1].name})"
  end

  def used?
    !new_record?
  end

  private

  def tag_must_be_valid
    errors.add :tag, :invalid_iso_code unless ISO::Tag.new(tag).valid?
  end
end
