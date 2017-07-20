# TODO analysis: switch to http://www.theimdbapi.org/
class ImdbScraper < ApplicationScraper

  def self.provider
    :imdb
  end

  def self.search query:

    results = search_imdb query: query

    if results.blank? && m = query.match(/^(.+)\s+\([^\)]+\)\s*$/)
      results = search_imdb query: m[1]
    end

    results.inject [] do |memo,imdb_result|

      link = imdb_result.css 'a[href]'
      next memo unless link

      url = IMDB_URL + link.attribute('href').try(:value)
      media_url = MediaUrl.resolve url: url
      next memo unless media_url && media_url.provider.to_s == provider.to_s

      image = imdb_result.at_css 'img[src]'
      next memo unless image

      result = {
        image: image.attribute('src').try(:value),
        url: media_url.url
      }

      title = imdb_result.at_css('.result_text').try(:content).try(:strip)
      result[:title] = title if title.present?

      memo << result
    end
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
    imdb_type = data['Type'].to_s.downcase

    if imdb_type != 'movie' && imdb_type != 'series'
      raise "Unsupported OMDB data type #{imdb_type.inspect}"
    end

    work = find_or_build_work scrap

    work.properties['movieType'] = imdb_type

    title = data['Title'].to_s.strip
    if imdb_blank?(title)
      raise "OMDB data has no title"
    end

    data_language = Language.find_or_create_by!(tag: 'en')

    if work.titles.find{ |t| t.contents == title }.blank?
      work.titles.build work: work, contents: title, language: data_language, display_position: work.titles.length
    end

    year = data['Year'].to_s.strip
    if imdb_blank?(year)
      raise "OMDB data has no year"
    end

    work.start_year = year.to_i
    work.end_year = year.to_i

    description = data['Plot'].to_s.strip
    add_work_description scrap: scrap, work: work, description: description, language: data_language unless imdb_blank?(description)

    work.language = data_language
    language_string = data['Language'].to_s.strip
    unless imdb_blank?(language_string)

      language = Language.full_list.find{ |l| l.name == language_string }
      if language.present?
        language.save! if language.new_record?
        work.language = language
      else
        scrap.warnings << %/Could not resolve language from "Language" property "#{language_string}"/
      end
    end

    if work.image.blank?
      image_url = data['Poster'].to_s.strip
      work.build_image.url = image_url unless imdb_blank?(image_url)
    end

    rating = data['Rated'].to_s.strip
    work.properties['rating'] = rating unless imdb_blank?(rating)

    genres_string = data['Genre'].to_s.strip
    unless imdb_blank?(genres_string)
      if match = genres_string.match(/^[^,]+(?:, [^,]+)*$/i)
        add_work_genres work: work, genres: genres_string.split(', ').collect(&:capitalize)
      else
        scrap.warnings << %/The "Genre" property is not in the expected comma-delimited format: "#{genres_string}"/
      end
    end

    countries = data['Country'].to_s.strip
    work.properties['countries'] = countries.split(', ') unless imdb_blank?(countries)

    awards = data['Awards'].to_s.strip
    work.properties['awards'] = awards unless imdb_blank?(awards)

    metascore = data['Metascore'].to_s.strip
    work.properties['metascore'] = metascore unless imdb_blank?(metascore)

    imdb_rating = data['imdbRating'].to_s.strip
    work.properties['imdbRating'] = imdb_rating unless imdb_blank?(imdb_rating)

    imdb_votes = data['imdbVotes'].to_s.strip.gsub(/,/, '')
    work.properties['imdbVotes'] = imdb_votes unless imdb_blank?(imdb_votes)

    add_people scrap: scrap, work: work, property: 'Director', string: data['Director'], relation: 'Director'
    add_people scrap: scrap, work: work, property: 'Writer', string: data['Writer'], relation: 'Writer'
    add_people scrap: scrap, work: work, property: 'Actors', string: data['Actors'], relation: 'Actor'

    save_work! work

    item = find_or_build_single_item scrap, work

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

    save_item! item
  end

  private

  OMDB_URL = 'http://www.omdbapi.com'
  IMDB_URL = 'http://www.imdb.com'
  IMDB_SEARCH_URL = 'http://www.imdb.com/find'

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

  def self.search_imdb query:

    start = Time.now

    res = HTTParty.get(IMDB_SEARCH_URL, query: {
      'q' => Rack::Utils.escape(query.strip),
      's' => 'tt' # search for titles only (not actors and other items)
    })

    duration = (Time.now.to_f - start.to_f).round 3
    Rails.logger.debug %/IMDB search for "#{query}" performed in #{duration}s/

    doc = Nokogiri::HTML res.body

    doc.css '.findResult'
  end

  def self.add_people scrap:, work:, property:, string:, relation:

    string = string.to_s.strip
    return if imdb_blank?(string)

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

      memo << {
        first_names: name_parts[0],
        last_name: name_parts[1],
        relation: relation
      }
    end

    add_work_relationships scrap: scrap, work: work, relationships_data: relationships_data
  end

  def self.imdb_blank? data
    data.blank? || data.downcase == 'n/a'
  end
end
