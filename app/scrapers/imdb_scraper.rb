class ImdbScraper < ApplicationScraper

  def self.provider
    :imdb
  end

  def self.scrap scrap
    contents = fetch_data scrap.media_url
    scrap.contents = contents
    scrap.content_type = 'application/json'
  end

  def self.expand scrap

    scrap.warnings.clear
    media_url = scrap.media_url

    data = JSON.parse scrap.contents
    data_type = data['Type'].to_s.downcase

    if data_type != 'movie'
      raise "Unsupported OMDB data type #{data_type.inspect}: #{scrap.contents}"
    end

    work = find_or_build_work scrap

    title = data['Title'].to_s.strip
    if title.blank?
      raise "OMDB data has no title: #{scrap.contents}"
    end

    data_language = Language.find_or_create_by!(tag: 'en')

    if work.titles.find{ |t| t.contents == title }.blank?
      work.titles.build work: work, contents: title, language: data_language, display_position: work.titles.length
    end

    year = data['Year'].to_s.strip
    if year.blank?
      raise "OMDB data has no year: #{scrap.contents}"
    end

    work.start_year = year.to_i
    work.end_year = year.to_i

    description = data['Plot'].to_s.strip
    add_work_description scrap: scrap, work: work, description: description, language: data_language

    work.language = data_language
    language_string = data['Language'].to_s.strip
    if language_string.present?

      language = Language.full_list.find{ |l| l.name == language_string }
      if language.present?
        language.save! if language.new_record?
        work.language = language
      else
        scrap.warnings << %/Could not resolve language from "Language" property "#{language_string}"/
      end
    end

    if work.image.blank?
      image = data['Poster'].to_s.strip
      if image.present?
        work.build_image.url = image
      end
    end

    rating = data['Rated'].to_s.strip
    work.properties['rating'] = rating if rating.present?

    genres_string = data['Genre'].to_s.strip
    if genres_string.present?
      if match = genres_string.match(/^[^,]+(?:, [^,]+)*$/i)
        add_work_genres genres_string.split(', ').collect(&:capitalize)
      else
        scrap.warnings << %/The "Genre" property is not in the expected comma-delimited format: "#{genres_string}"/
      end
    end

    countries = data['Country'].to_s.strip.split(', ')
    work.properties['countries'] = countries if countries.present?

    awards = data['Awards'].to_s.strip
    work.properties['awards'] = awards if awards.present?

    metascore = data['Metascore'].to_s.strip
    work.properties['metascore'] = metascore if metascore.present?

    imdb_rating = data['imdbRating'].to_s.strip
    work.properties['imdbRating'] = imdb_rating if imdb_rating.present?

    imdb_votes = data['imdbVotes'].to_s.strip.gsub(/,/, '')
    work.properties['imdbVotes'] = imdb_votes if imdb_votes.present?

    add_people scrap: scrap, work: work, property: 'Director', string: data['Director'], relation: 'Director'
    add_people scrap: scrap, work: work, property: 'Writer', string: data['Writer'], relation: 'Writer'
    add_people scrap: scrap, work: work, property: 'Actors', string: data['Actors'], relation: 'Actor'

    save_work! work

    item = find_existing_item work, media_url

    if item.present?
      item.cache_previous_version
      item.updater = scrap.creator
    else
      item = Video.new
      item.work = work
      item.media_url = media_url
      item.creator = scrap.creator
    end

    item.title ||= work.original_title
    item.language ||= work.language

    if item.image.blank? && work.image.present?
      item.build_image.url = work.image.url
    end

    if item.original_release_date.blank?
      item.original_release_date = Date.new work.start_year
      item.original_release_date_precision = 'y'
    end

    runtime = data['Runtime'].to_s.strip.downcase
    if match = runtime.match(/^(\d+) min$/)
      item.length ||= match[1].to_i
    end

    item.clean_properties
    if item.tree_new_or_changed?
      item.save!
    end
  end

  private

  OMDB_URL = 'http://www.omdbapi.com'

  def self.fetch_data media_url

    res = HTTParty.get(OMDB_URL, query: {
      'i' => media_url.provider_id,
      'plot' => 'full',
      'r' => 'json'
    })

    json = res.body
    result = JSON.parse json

    response_successful = result.key?('Response') && result['Response'].to_s.match(/^true$/i)
    if !response_successful
      raise "Received unexpected non-true OMDB response: #{res.body}"
    end

    imdb_id = result['imdbID'].to_s
    if imdb_id.downcase != media_url.provider_id.downcase
      raise "Received unexpected OMDB response with IMDB ID mismatch: #{res.body}"
    end

    json
  end

  def self.add_people scrap:, work:, property:, string:, relation:

    string = string.to_s.strip
    return if string.blank?

    person_regexp = /^([a-z]+ [a-z]+)(?: \(([^\(\)]+)\))?/i

    person_strings = string.split /, /
    unless person_strings.all?{ |p| p.match person_regexp }
      scrap.warnings << %/Format of "#{property}" property is not supported: #{string}/
      return
    end

    details_by_name = person_strings.inject({}) do |memo,person_string|
      match = person_string.match person_regexp
      full_name = match[1]
      details = match[2]

      memo[full_name] = [ memo[full_name], details ].compact.flatten
      memo
    end

    relationships_data = details_by_name.inject([]) do |memo,(full_name,details)|
      name_parts = full_name.split(/ /)

      {
        first_names: name_parts[0],
        last_name: name_parts[1],
        relation: relation
      }
    end

    add_work_relationships relationships_data
  end
end
