module SpecModelExpectationsHelper
  def expect_item json, options = {}

    item = Item.where(api_id: json['id']).includes([ :language, { links: :language }, { titles: :language }, :descriptions, { relationships: :person } ]).first
    expect(item).to be_present

    %w(category start_year end_year number_of_parts).each do |attr|
      expect(item.send(attr)).to eq(json[attr.camelize(:lower)])
    end

    expect(item.language.tag).to eq(json['language'])

    expect(item.titles).to have(json['titles'].length).items
    json['titles'].each.with_index do |title,i|
      expect(item.titles[i].api_id).to eq(title['id'])
      expect(item.titles[i].contents).to eq(title['text'])
      expect(item.titles[i].language.tag).to eq(title['language'])
    end

    expect(item.original_title).to eq(item.titles[0])

    relationships = json['relationships'] || [] # TODO: check that relationship people are unique
    expect(item.relationships).to have(relationships.length).items
    relationships.each.with_index do |rel,i|
      matching_rel = item.relationships.find{ |item_rel| item_rel.person.api_id == rel['personId'] }
      expect(matching_rel).to be_present, "expected item #{json['id']} to have a relationship with person #{rel['personId']}"
      expect(matching_rel.relationship).to eq(rel['relation'])
    end

    links = json['links'] || [] # TODO: check that link URLs are unique
    expect(item.links).to have(links.length).items
    links.each.with_index do |link,i|
      matching_link = item.links.find{ |item_link| item_link.url == link['url'] }
      expect(matching_link).to be_present, "expected item #{json['id']} to have a link with URL #{link['url']}"
      if link.key? 'language'
        expect(matching_link.language.tag).to eq(link['language'])
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
