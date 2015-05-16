module SpecModelExpectationsHelper
  def expect_ownership json, options = {}

    ownership = Ownership.where(api_id: json['id']).includes(:item_part, :user).first
    expect(ownership).to be_present

    expect(ownership.item_part.api_id).to eq(json['partId'])
    expect(ownership.user.api_id).to eq(json['userId'])
    expect(ownership.gotten_at.iso8601(3)).to eq(json['gottenAt'])
    expect(ownership.tags).to eq(json['tags'])

    raise ":creator option is required" unless options.key? :creator
    expect(ownership.creator).to eq(options[:creator])
    expect(ownership.updater).to eq(options[:updater] || options[:creator])

    ownership
  end

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

  def expect_ownership json, options = {}

    ownership = Ownership.where(api_id: json['id']).first
    expect(ownership).to be_present

    expect(ownership.item_part.api_id).to eq(json['partId'])
    expect(ownership.user.api_id).to eq(json['userId'])
    expect(ownership.gotten_at.iso8601(3)).to eq(json['gottenAt'])
    expect(ownership.tags).to eq(json['tags'])

    raise ":creator option is required" unless options.key? :creator
    expect(ownership.creator).to eq(options[:creator])
    expect(ownership.updater).to eq(options[:updater] || options[:creator])
  end

  def expect_part json, options = {}

    part = ItemPart.where(api_id: json['id']).includes(:item, { title: :language }, :custom_title_language, :language).first
    expect(part).to be_present

    item = Item.where(api_id: json['itemId']).first
    expect(item).to be_present
    expect(part.item).to eq(item)

    if json.key? 'titleId'
      title = item.titles.where(api_id: json['titleId']).first
      expect(title).to be_present
      expect(part.title).to eq(title)
      expect(part.effective_title).to eq(json['title']['text'])
      expect(part.title.language.tag).to eq(json['title']['language'])
      expect(part.custom_title).to be_nil
      expect(part.custom_title_language).to be_nil
    else
      expect(part.title).to be_nil
      expect(part.custom_title).to eq(json['title']['text'])
      expect(part.custom_title_language.tag).to eq(json['title']['language'])
    end

    expect(part.original_year).to eq(json['originalYear'])
    expect(part.year).to json.key?('year') ? eq(json['year']) : be_nil
    expect(part.language.tag).to eq(json['language'])
    expect(part.range_start).to json.key?('start') ? eq(json['start']) : be_nil
    expect(part.range_end).to json.key?('end') ? eq(json['end']) : be_nil
    expect(json.key?('start')).to eq(json.key?('end')) # custom error message
    expect(part.edition).to json.key?('edition') ? eq(json['edition']) : be_nil
    expect(part.version).to json.key?('version') ? eq(json['version']) : be_nil
    expect(part.format).to json.key?('format') ? eq(json['format']) : be_nil
    expect(part.length).to json.key?('length') ? eq(json['length']) : be_nil
    expect(part.tags).to eq(json['tags'])

    # TODO: test with item
    # TODO: test ownedByMe
    # TODO: test with image

    raise ":creator option is required" unless options.key? :creator
    expect(part.creator).to eq(options[:creator])
    expect(part.updater).to eq(options[:updater] || options[:creator])

    part
  end

  def expect_item json, options = {}

    item = Item.where(api_id: json['id']).includes([ :language, { links: :language }, { titles: :language }, :descriptions, { relationships: :person } ]).first
    expect(item).to be_present

    %w(category start_year end_year number_of_parts).each do |attr|
      expect(item.send(attr)).to eq(json[attr.camelize(:lower)])
    end

    expect(item.language.tag).to eq(json['language'])

    item_titles = item.titles.sort_by &:display_position
    expect(item_titles).to have(json['titles'].length).items
    json['titles'].each.with_index do |title,i|
      expect(item_titles[i].to_builder.attributes!).to eq(title)
    end

    expect(item.original_title).to eq(item_titles[0])

    relationships = json['relationships'] || [] # TODO: check that relationship people are unique
    expect(item.relationships).to have(relationships.length).items
    relationships.each.with_index do |rel,i|
      matching_rel = item.relationships.find{ |item_rel| item_rel.person.api_id == rel['personId'] }
      expect(matching_rel).to be_present, "expected item #{json['id']} to have a relationship with person #{rel['personId']}"
      expect(matching_rel.relationship).to eq(rel['relation']) # TODO custom error message
    end

    links = json['links'] || [] # TODO: check that link URLs are unique
    expect(item.links).to have(links.length).items
    links.each.with_index do |link,i|
      matching_link = item.links.find{ |item_link| item_link.url == link['url'] }
      expect(matching_link).to be_present, "expected item #{json['id']} to have a link with URL #{link['url']}"
      if link.key? 'language'
        expect(matching_link.language.tag).to eq(link['language']) # TODO: custom error message
      else
        expect(matching_link.language).to be_nil
      end
    end

    expect(item.tags).to eq(json['tags'] || {})

    raise ":creator option is required" unless options.key? :creator
    expect(item.creator).to eq(options[:creator])
    expect(item.updater).to eq(options[:updater] || options[:creator])

    item
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
end
