class ApplicationScraper
  def self.scraps? media_url
    media_url.provider.to_s == provider.to_s
  end

  def self.find_existing_work media_url
    Work.joins(:media_url).where('media_urls.id = ?', media_url.id).first
  end

  def self.find_existing_item work, media_url
    Item.joins(:media_url).where(work_id: work.id).where('media_urls.id = ?', media_url.id).first
  end

  def self.find_or_build_work scrap
    work = find_existing_work scrap.media_url

    if work.present?
      work.cache_previous_version
      work.updater = scrap.creator
    else
      work = Work.new
      work.media_url = scrap.media_url
      work.creator = scrap.creator
    end

    work.media_scrap = scrap
    work.category = scrap.media_url.category

    work
  end

  def self.add_work_link scrap:, work:, link_url:
    return if link_url.blank?

    if link_url.length > 255
      scrap.warnings << "Did not use URL because it is longer than 255 characters (#{link_url.length}): #{link_url}"
      return
    end

    link_url = link_url.downcase

    unless existing_link = work.links.where(url: link_url).first
      work.links.build url: link_url
    end
  end

  def self.add_work_description scrap:, work:, description:, language:
    return if description.blank?

    if description.length > 5000
      description = description.truncate 5000
      scrap.warnings << "Truncated description because it is longer than 5000 characters"
    end

    if existing_description = work.descriptions.where(language: language).first
      existing_description.contents = description
    else
      work.descriptions.build contents: description, language: language
    end
  end

  def self.add_work_relationships scrap:, work:, relationships_data:
    return if relationships_data.blank?

    expected_keys = %i(first_names last_name pseudonym relation details)

    relationships_data.each do |relationship|

      extra_keys = relationship.keys - expected_keys
      if extra_keys.any?
        raise "Relationship data contains unexpected keys #{extra_keys.join(', ')}: #{relationship.inspect}"
      end

      first_names = relationship[:first_names]
      last_name = relationship[:last_name]
      pseudonym = relationship[:pseudonym]
      relation = relationship[:relation]
      details = relationship[:details]

      person = Person.where(first_names: first_names, last_name: last_name, pseudonym: pseudonym).first
      if person.blank?
        person = Person.new first_names: first_names, last_name: last_name, pseudonym: pseudonym
        person.creator_optional = true
        person.save!
      end

      relationships = work.person_relationships.where(relation: relation).includes(:person).to_a

      if existing_relationship = relationships.find{ |r| r.person == person && r.relation == relation }
        existing_relationship.details = details
      else
        relationship = WorkPerson.new work: work, person: person, relation: relation, details: details
        work.person_relationships << relationship
      end
    end
  end

  def self.add_work_genres work:, genres:
    genres.each do |name|
      genre = Genre.where(normalized_name: name.downcase).first || Genre.new(name: name).tap(&:save!)
      work.genres << genre unless work.genres.include? genre
    end
  end

  def self.add_work_tags work:, tags:
    tags.each do |name|
      tag = Tag.where(normalized_name: name.downcase).first || Tag.new(name: name).tap(&:save!)
      work.tags << tag unless work.tags.include? tag
    end
  end

  def self.save_work! work
    work.clean_properties
    if work.tree_new_or_changed?
      work.save!
      work.update_columns original_title_id: work.titles.where(display_position: 0).first.id
    end
  end
end
