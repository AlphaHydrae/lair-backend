module SpecModelExpectationsHelper
  def expect_person json, options = {}

    person = Person.where(api_id: json['id']).first
    expect(person).to be_present

    expect(person.first_names).to json.key?('firstNames') ? eq(json['firstNames']) : be_nil
    expect(person.last_name).to json.key?('lastName') ? eq(json['lastName']) : be_nil
    expect(person.pseudonym).to json.key?('pseudonym') ? eq(json['pseudonym']) : be_nil

    raise ":creator option is required" unless options.key? :creator
    expect(person.creator).to eq(options[:creator])
    expect(person.updater).to eq(options[:updater] || options[:creator])

    person
  end

  def expect_company json, options = {}

    company = Company.where(api_id: json['id']).first
    expect(company).to be_present

    expect(company.name).to json.key?('name') ? eq(json['name']) : be_nil

    raise ":creator option is required" unless options.key? :creator
    expect(company.creator).to eq(options[:creator])
    expect(company.updater).to eq(options[:updater] || options[:creator])

    company
  end

  def expect_ownership json, options = {}

    ownership = Ownership.where(api_id: json['id']).includes(:item, :user).first
    expect(ownership).to be_present

    expect(ownership.item.api_id).to eq(json['itemId'])
    expect(ownership.user.api_id).to eq(json['userId'])
    expect(ownership.gotten_at.iso8601(3)).to eq(json['gottenAt'])
    expect(ownership.properties).to eq(json['properties'])

    raise ":creator option is required" unless options.key? :creator
    expect(ownership.creator).to eq(options[:creator])
    expect(ownership.updater).to eq(options[:updater] || options[:creator])

    ownership
  end

  def expect_item json, options = {}

    item = Item.where(api_id: json['id']).includes(:work, { title: :language }, :custom_title_language, :language).first
    expect(item).to be_present

    expect(item).to be_a(Volume) if json['type'] == 'volume'
    expect(item).to be_a(Video) if json['type'] == 'video'

    work = Work.where(api_id: json['workId']).first
    expect(work).to be_present
    expect(item.work).to eq(work)

    title = work.titles.where(api_id: json['titleId']).first
    expect(title).to be_present
    expect(item.title).to eq(title)
    expect(item.effective_title).to eq(json['title']['text'])

    if json.key? 'customTitle'
      expect(item.custom_title).to eq(json['title']['text'])
      expect(item.custom_title_language.tag).to eq(json['title']['language'])
    else
      expect(item.title.language.tag).to eq(json['title']['language'])
      expect(item.custom_title).to be_nil
      expect(item.custom_title_language).to be_nil
    end

    expect_date_with_precision item, json, :original_release_date
    expect_date_with_precision item, json, :release_date, required: false
    expect(item.language.tag).to eq(json['language'])
    expect(item.range_start).to json.key?('start') ? eq(json['start']) : be_nil
    expect(item.range_end).to json.key?('end') ? eq(json['end']) : be_nil
    expect(json.key?('start')).to eq(json.key?('end')) # custom error message
    expect(item.edition).to json.key?('edition') ? eq(json['edition']) : be_nil
    expect(item.version).to json.key?('version') ? eq(json['version']) : be_nil
    expect(item.format).to json.key?('format') ? eq(json['format']) : be_nil
    expect(item.length).to json.key?('length') ? eq(json['length']) : be_nil
    expect(item.properties).to eq(json['properties'])

    if item.kind_of? Volume
      expect(item.publisher).to json.key?('publisher') ? eq(json['publisher']) : be_nil
      expect(item.isbn).to json.key?('isbn') ? eq(json['isbn']) : be_nil
    end

    if item.kind_of? Video
      expect(item.audio_languages.collect(&:tag)).to json.key?('audioLanguages') ? match_array(json['audioLanguages']) : be_empty
      expect(item.subtitle_languages.collect(&:tag)).to json.key?('subtitleLanguages') ? match_array(json['subtitleLanguages']) : be_empty
    end

    # TODO: test with work
    # TODO: test ownedByMe
    # TODO: test with image

    raise ":creator option is required" unless options.key? :creator
    expect(item.creator).to eq(options[:creator])
    expect(item.updater).to eq(options[:updater] || options[:creator])

    item
  end

  def expect_work json, options = {}

    work = Work.where(api_id: json['id']).includes([ :language, { links: :language }, { titles: :language }, :descriptions, { person_relationships: :person, company_relationships: :company } ]).first
    expect(work).to be_present

    %w(category start_year end_year number_of_items).each do |attr|
      expect(work.send(attr)).to eq(json[attr.camelize(:lower)])
    end

    expect(work.language.tag).to eq(json['language'])

    work_titles = work.titles.sort_by &:display_position
    expect(work_titles).to have(json['titles'].length).items
    json['titles'].each.with_index do |title,i|
      matching_title = work_titles[i]
      expect(matching_title.api_id).to eq(title['id'])
      expect(matching_title.contents).to eq(title['text'])
      expect(matching_title.language.tag).to eq(title['language'])
    end

    expect(work.original_title).to eq(work_titles[0])

    relationships = json['relationships'] || [] # TODO: check that relationship people are unique

    person_relationships = relationships.select{ |r| r.key? 'personId' }
    expect(work.person_relationships).to have(person_relationships.length).items
    person_relationships.each.with_index do |rel,i|
      matching_rel = work.person_relationships.find{ |work_rel| work_rel.person.api_id == rel['personId'] }
      expect(matching_rel).to be_present, "expected work #{json['id']} to have a relationship with person #{rel['personId'].inspect}"
      expect(matching_rel.relation).to eq(rel['relation']) # TODO custom error message
      expect(matching_rel.details).to rel.key?('details') ? eq(rel['details']) : be_nil
    end

    company_relationships = relationships.select{ |r| r.key? 'companyId' }
    expect(work.company_relationships).to have(company_relationships.length).items
    company_relationships.each.with_index do |rel,i|
      matching_rel = work.company_relationships.find{ |work_rel| work_rel.company.api_id == rel['companyId'] }
      expect(matching_rel).to be_present, "expected work #{json['id']} to have a relationship with company #{rel['companyId'].inspect}"
      expect(matching_rel.relation).to eq(rel['relation'].underscore) # TODO custom error message
      expect(matching_rel.details).to rel.key?('details') ? eq(rel['details']) : be_nil
    end

    links = json['links'] || [] # TODO: check that link URLs are unique
    expect(work.links).to have(links.length).items
    links.each.with_index do |link,i|
      matching_link = work.links.find{ |work_link| work_link.url == link['url'] }
      expect(matching_link).to be_present, "expected work #{json['id']} to have a link with URL #{link['url']}"
      if link.key? 'language'
        expect(matching_link.language.tag).to eq(link['language']) # TODO: custom error message
      else
        expect(matching_link.language).to be_nil
      end
    end

    expect(work.properties).to eq(json['properties'] || {})

    raise ":creator option is required" unless options.key? :creator
    expect(work.creator).to eq(options[:creator])
    expect(work.updater).to eq(options[:updater] || options[:creator])

    work
  end

  def expect_model_event type, user, trackable, options = {}

    event = Event.where(event_type: type.to_s, user: user, trackable: trackable).includes(:cause).first
    expect(event).to be_present, "expected to find an event of type #{type} by user #{user.api_id} for #{trackable.class.name} #{trackable.api_id}"

    expect(event.cause).to be_nil
    expect(event.event_subject).to be_nil
    expect(event.api_version).to eq(Rails.application.api_version)

    if options.key? :previous_version
      expect(event.previous_version).to eq(options[:previous_version])
    else
      expect(event.previous_version).to be_nil
    end
  end

  private

  def expect_date_with_precision record, json, attr, options = {}

    required = options.fetch :required, true
    json_key = attr.to_s.camelize :lower

    if !json.key?(json_key) && !required
      expect(record.send(attr)).to be_nil
      return
    end

    expect(record.send(attr)).to be_present

    value = json[json_key]
    expect(value).to match(/\A\d+(?:-[01]\d(?:-[0123]\d)?)?\Z/)

    case value.split('-').length
    when 1
      expect(record.send(attr).iso8601).to eq("#{value}-01-01")
      expect(record.send("#{attr}_precision")).to eq('y')
    when 2
      expect(record.send(attr).iso8601).to eq("#{value}-01")
      expect(record.send("#{attr}_precision")).to eq('m')
    else
      expect(record.send(attr).iso8601).to eq(value)
      expect(record.send("#{attr}_precision")).to eq('d')
    end
  end
end
