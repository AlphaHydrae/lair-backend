class ImdbScraper < ApplicationScraper

  def self.scraps? media_url
    media_url.provider.to_s == 'imdb'
  end

  def self.provider
    :imdb
  end

  def self.scrap scrap
    parsed_contents = fetch_data scrap.media_url
    scrap.contents = JSON.dump parsed_contents
    scrap.content_type = 'application/json'
  end

  def self.expand scrap
    media_url = scrap.media_url

    work = find_existing_work media_url

    if work.present?
      work.cache_previous_version
      work.updater = scrap.creator
    else
      work = Work.new
      work.media_url = media_url
      work.creator = scrap.creator
    end

    data = JSON.parse scrap.contents
    data_type = data['Type'].to_s
    data_language = Language.find_or_create_by!(tag: 'en')

    raise "Unsupported OMDB data type #{data_type.inspect}: #{scrap.contents}" if data_type != 'movie'

    work.scrap = scrap
    work.category = media_url.category

    title = data['Title'].to_s.strip
    if title.blank?
      raise "OMDB data has no title: #{scrap.contents}"
    end

    if work.titles.find{ |t| t.contents == title }.blank?
      work.titles.build work: work, contents: title, language: data_language, display_position: work.titles.length
    end

    year = data['Year'].to_s.strip
    if year.blank?
      raise "OMDB data has no year: #{scrap.contents}"
    end

    work.start_year = year.to_i
    work.end_year = year.to_i

    # TODO: parse director, writer, actors

    description = data['Plot'].to_s.strip
    if description.present?
      work.descriptions << WorkDescription.new(work: work, contents: description, language: data_language)
    end

    work.language = data_language
    language = data['Language'].to_s.strip
    if language.present?
      language = Language.full_list.find{ |l| l.name == language }
      if language.present?
        language.save! if language.new_record?
        work.language = language
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

    genres = data['Genre'].to_s.strip.split(', ').collect(&:downcase)
    work.properties['genres'] = genres if genres.present?

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

    work.save!
    work.update_columns original_title_id: work.titles.where(display_position: 0).first.id
  end

  private

  OMDB_URL = 'http://www.omdbapi.com'

  def self.fetch_data media_url
    res = HTTParty.get(OMDB_URL, query: {
      'i' => media_url.provider_id,
      'plot' => 'full',
      'r' => 'json'
    })

    result = JSON.parse res.body

    response_successful = result.key?('Response') && result['Response'].to_s.match(/^true$/i)
    if !response_successful
      raise "Received unexpected non-true OMDB response: #{res.body}"
    end

    imdb_id = result['imdbID'].to_s
    if imdb_id.downcase != media_url.provider_id.downcase
      raise "Received unexpected OMDB response with IMDB ID mismatch: #{res.body}"
    end

    result
  end
end
