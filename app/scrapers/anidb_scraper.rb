require 'zlib'
require 'stringio'

class AnidbScraper < ApplicationScraper
  def self.scraper
    :anidb
  end

  def self.provider
    :anidb
  end

  def self.search query:

    dump = latest_anidb_dump

    document = Ox.parse dump.content
    anime_elements = locate document.root, 'anime'

    results = search_anidb_titles query: query, anime_elements: anime_elements

    if results.blank?
      searchable_query_parts = query.to_s.strip.downcase.split(/\s+/).select{ |p| p.length >= 4 }.sort{ |a,b| b.length <=> a.length }
      results = searchable_query_parts.inject [] do |memo,searchable_query_part|
        memo + search_anidb_titles(query: searchable_query_part, anime_elements: anime_elements)
      end

      results.sort! do |a,b|
        qualities = [ a, b ].collect{ |result| searchable_query_parts.inject(0){ |memo,part| part = part.to_s.strip.downcase; memo + (result[:title].to_s.downcase.index(part) ? part.length : 0) } }
        diff = qualities[1] <=> qualities[0]
        if diff != 0
          puts "#{a[:title]} = #{qualities[0]} ||| #{b[:title]} = #{qualities[1]}"
          diff
        else
          a[:title] <=> b[:title]
        end
      end
    end

    results.uniq!{ |result| result[:url] }

    results.length > 250 ? results[0, 250] : results
  end

  def self.scraps? *args
    config[:enabled] && super(*args)
  end

  def self.scrap scrap
    contents = fetch_data scrap.media_url
    scrap.contents = contents
    scrap.content_type = 'application/xml'
  end

  def self.expand scrap

    scrap.warnings.clear
    media_url = scrap.media_url

    document = Ox.parse scrap.contents

    root = document.root

    type_element = locate_one(root, 'type', required: true)
    anidb_type = element_text type_element

    anidb_type = if anidb_type == 'TV Series'
      :tv_series
    elsif anidb_type == 'Movie'
      :movie
    elsif anidb_type == 'OVA'
      :ova
    elsif anidb_type == 'TV Special'
      :tv_special
    elsif anidb_type == 'Web'
      :web
    else
      raise "Unsupported AniDB data type #{Ox.dump(type_element)}"
    end

    work = find_or_build_work scrap

    data_language = Language.find_or_create_by! tag: 'en'
    anidb_default_language = Language.find_or_create_by! tag: 'ja'

    work.language = anidb_default_language

    start_date = parse_anidb_date element_text(locate_one(root, 'startdate')), path: '/anime/startdate'
    work.start_year = start_date.try(:year)

    end_date = parse_anidb_date element_text(locate_one(root, 'enddate')), path: '/anime/enddate'
    work.end_year = end_date.try(:year)

    episode_count = element_text(locate_one(root, 'episodecount')).try(:to_i)
    if episode_count.present? && episode_count >= 2
      work.number_of_items = episode_count
    end

    title_elements = locate root, 'titles/title', min: 1
    add_titles work: work, title_elements: title_elements

    description = anidb_text_to_markdown element_text(locate_one(root, 'description'))
    add_work_description scrap: scrap, work: work, description: description, language: data_language

    image = element_text locate_one(root, 'picture')
    if image.present? && work.image.blank?
      work.build_image.url = anidb_image_url image
    end

    work.properties['animeType'] = anidb_type.to_s

    permanent_rating_element = locate_one(root, 'ratings/permanent')
    if permanent_rating_element.present?
      work.properties['anidbPermanentRating'] = element_text permanent_rating_element
      work.properties['anidbPermanentVotesCount'] = permanent_rating_element['count']
    end

    temporary_rating_element = locate_one(root, 'ratings/temporary')
    if temporary_rating_element.present?
      work.properties['anidbTemporaryRating'] = element_text temporary_rating_element
      work.properties['anidbTemporaryVotesCount'] = temporary_rating_element['count']
    end

    review_rating_element = locate_one(root, 'ratings/review')
    if review_rating_element.present?
      work.properties['anidbReviewRating'] = element_text review_rating_element
      work.properties['anidbReviewVotesCount'] = review_rating_element['count']
    end

    link_url = element_text locate_one(root, 'url')
    add_work_link scrap: scrap, work: work, link_url: link_url

    creator_name_elements = locate(root, 'creators/name')
    add_people scrap: scrap, work: work, name_elements: creator_name_elements

    add_tags scrap: scrap, work: work, tag_elements: locate(root, 'tags/tag')

    save_work! work

    episode_elements = locate(root, 'episodes/episode', required: true)

    if episode_count == 1

      main_item = find_or_build_single_item scrap, work
      anidb_episode = find_anidb_episode episode_elements, 1

      if anidb_episode.blank?
        raise "Could not find episode 1"
      end

      main_item.build_image.url = work.image.url if work.image.present?

      update_item_from_anidb_episode item: main_item, episode: anidb_episode, scrap: scrap
      save_item! main_item
    else

      main_episode_elements = filter_anidb_episodes episode_elements, /^\d+$/i
      if main_episode_elements.length != episode_count
        scrap.warnings << "Expected series episode count #{episode_count} to match number of numbered <episode> elements #{main_episode_elements.length}"
      end

      main_episode_elements.each do |episode_element|

        episode_number = element_text(locate_one(episode_element, 'epno', required: true)).to_i
        episode_item = find_or_build_item scrap, work, episode_number, episode_number

        update_item_from_anidb_episode item: episode_item, episode: episode_element, scrap: scrap
        save_item! episode_item
      end
    end

    special_episode_elements = filter_anidb_episodes episode_elements, /^S\d+$/i

    special_episode_elements.each do |episode_element|

      episode_number = element_text(locate_one(episode_element, 'epno', required: true)).to_s.sub(/^S/, '').to_i
      episode_item = find_or_build_item scrap, work, episode_number, episode_number, true

      valid = update_item_from_anidb_episode item: episode_item, episode: episode_element, special: true, scrap: scrap
      save_item! episode_item if valid
    end
  end

  private

  ANIDB_URL = 'http://api.anidb.net:9001/httpapi?request=anime&client=%{client_id}&clientver=%{client_version}&protover=1&aid=%{anime_id}'
  ANIDB_IMAGE_URL = 'http://img7.anidb.net/pics/anime/%{image}'
  ANIDB_DUMP_URL = 'http://anidb.net/api/anime-titles.xml.gz'

  def self.latest_anidb_dump

    dump = MediaDump.where(provider: provider.to_s, category: 'titles').order('created_at DESC').first
    if dump.present? && Time.now - dump.created_at < 1.week
      Rails.logger.debug "Using latest AniDB title dump from #{dump.created_at}"
      return dump
    end

    unless $redis.set 'anidb:dump:throttle', true, ex: 2.days.to_i, nx: true
      raise "Could not retrieve AniDB title dump" unless dump
      Rails.logger.debug "Using latest AniDB title dump from #{dump.created_at} due to throttling"
      return dump
    end

    start = Time.now
    latest_dump = MediaDump.new provider: provider.to_s, category: 'titles'

    res = HTTParty.get ANIDB_DUMP_URL

    duration = (Time.now.to_f - start.to_f).round 3
    Rails.logger.info "Downloaded latest AniDB title dump in #{duration}s"

    latest_dump.content = res.body.to_s
    latest_dump.content_type = 'application/xml'

    latest_dump.tap &:save!
  end

  def self.search_anidb_titles query:, anime_elements:

    query = query.to_s.strip.downcase

    matching_anime_elements = anime_elements.inject [] do |memo,anime_element|
      next memo unless anime_element['aid']

      title_elements = locate anime_element, 'title'
      matching_title = title_elements.find do |title_element|
        element_text(title_element).downcase.index query
      end

      if matching_title
        media_url = MediaUrl.new provider: provider, category: 'anime', provider_id: anime_element['aid']
        main_title_elements = title_elements.select{ |e| %w(main official).include?(e['type']) }

        memo << {
          url: media_url.url,
          title: main_title_elements.collect{ |t| element_text(t) }.join(', ')
        }
      end

      memo
    end
  end

  def self.fetch_data media_url

    url = ANIDB_URL % { client_id: config[:client_id], client_version: config[:client_version], anime_id: media_url.provider_id }

    res = HTTParty.get url
    xml = res.body

    result = begin
      Ox.parse xml
    rescue => e
      raise %/#{e.message.strip}:\n#{xml}/
    end

    root = result.root
    root_name = root.name.to_s

    if root_name == 'error'
      raise "Received error response from AniDB\n#{xml}"
    elsif root_name != 'anime'
      raise "Could not find required /anime root element\n#{xml}"
    elsif root[:id].to_s.strip.downcase != media_url.provider_id
      raise "Anime ID in response does not match the requested ID (#{media_url.provider_id})\n#{xml}"
    end

    xml
  end

  def self.add_titles work:, title_elements:
    return if title_elements.blank?

    selected_titles = filter_anidb_titles title_elements, %w(main official)

    title_data = selected_titles.inject([]) do |memo,title_element|

      text = element_text title_element
      next memo if text.blank? || memo.find{ |t| t[:text] == text }

      language_tag = title_element['xml:lang']
      language_tag = 'ja' if language_tag == 'x-jat'

      normalized_language_tag = language_tag.sub(/-.*/, '').downcase
      next memo unless ISO::Language.find normalized_language_tag

      memo << {
        text: text,
        type: title_element['type'],
        language: Language.where(tag: normalized_language_tag).first_or_create!
      }
    end

    main_title = title_data.find{ |t| t[:type] == 'main' }
    if main_title && main_title != title_data[0]
      title_data.delete main_title
      title_data.unshift main_title
    end

    existing_titles = work.titles.order('display_position ASC').to_a
    n = existing_titles.length

    title_data.each.with_index do |title,i|
      unless existing_titles.find{ |t| t.contents == title[:text] }
        work.titles.build contents: title[:text], language: title[:language], display_position: n + i
      end
    end
  end

  def self.add_people scrap:, work:, name_elements:
    return if name_elements.blank?

    data_by_name = name_elements.inject({}) do |memo,name_element|

      relation = name_element['type'].strip.humanize
      full_name = element_text name_element

      if relation.blank?
        scrap.warnings << "Did not include creator because no type was found: #{Ox.dump(name_element)}"
        next memo
      end

      first_names = nil
      last_name = nil
      pseudonym = nil

      if match = full_name.match(/^[a-z]+$/i)
        pseudonym = full_name
      elsif match = full_name.match(/^([a-z]+) ([a-z]+)$/i)
        first_names = match[2]
        last_name = match[1]
      else
        scrap.warnings << "Did not include creator because name does not have the expected format: #{Ox.dump(name_element)}"
        next memo
      end

      memo[full_name] ||= {
        first_names: first_names,
        last_name: last_name,
        pseudonym: pseudonym,
        relations: []
      }

      memo[full_name][:relations] << relation

      memo
    end

    relationships_data = data_by_name.inject([]) do |memo,(full_name,data)|
      data[:relations].uniq.each do |relation|
        memo << data.slice(:first_names, :last_name, :pseudonym).merge(relation: relation)
      end

      memo
    end

    add_work_relationships scrap: scrap, work: work, relationships_data: relationships_data
  end

  def self.add_tags scrap:, work:, tag_elements:
    return if tag_elements.blank?

    tags = tag_elements.each.with_index.inject([]) do |memo,(tag_element,i)|

      tag_name = element_text locate_one(tag_element, 'name', current_path: "/anime/tags/tag[#{i}]")
      if tag_name.blank?
        scrap.warnings << "Did not include tag because name is blank: #{Ox.dump(tag_element)}"
        next memo
      end

      weight = tag_element['weight'].to_i
      next memo if weight <= 0

      memo << tag_name
    end

    add_work_tags work: work, tags: tags.uniq.collect(&:humanize) if tags.present?
  end

  def self.update_item_from_anidb_episode item:, episode:, special: false, scrap:

    item.length = element_text(locate_one(episode, 'length')).try(:to_i)

    airdate_element = locate_one episode, 'airdate'
    if airdate_element
      item.original_release_date = parse_anidb_date element_text(airdate_element), path: '//episode/airdate'
      item.original_release_date_precision = 'd'
    elsif !special
      scrap.warnings << "Could not include #{Ox.dump(episode)} because it has no airdate"
      return false
    end

    title_elements = locate episode, 'title', required: true
    title_elements.select! do |title_element|
      language = title_element['xml:lang'].to_s.downcase
      language == 'x-jat' || !!language.match(/^[a-z]{2}$/)
    end

    main_title_element = find_anidb_title(title_elements, 'x-jat') || title_elements.first
    if main_title_element != title_elements.first
      title_elements.delete main_title_element
      title_elements.unshift main_title_element
    end

    i = 0
    title_elements.each do |title_element|

      contents = element_text title_element
      language = title_element['xml:lang']
      language = 'ja' if language == 'x-jat'

      unless item.titles.find{ |t| t.contents == contents && t.language.tag == language }

        if contents.length > 500
          scrap.warnings << "Truncated title because it is longer than 500 characters (#{contents.length}): #{contents}"
          contents = contents.truncate 500
        end

        item.titles.build contents: contents, language: Language.language(language), display_position: 0
        i += 1
      end
    end

    rating_element = locate_one episode, 'rating'
    if rating_element.present?
      item.properties['rating'] = element_text(rating_element).to_f
      votes = rating_element['votes'].to_s
      item.properties['ratingVotes'] = votes.to_i if votes.present?
    end

    recap = episode['recap'].to_s.match(/^true$/i)
    item.properties['recap'] = true if recap
  end

  def self.find_anidb_title title_elements, language
    title_elements.find do |title_element|
      title_element['xml:lang'].to_s.downcase == language.to_s.downcase
    end
  end

  def self.filter_anidb_titles title_elements, types
    title_elements.select do |title_element|
      types.include? title_element['type'].to_s.strip.downcase
    end
  end

  def self.find_anidb_episode episode_elements, number
    episode_elements.find do |episode_element|
      element_text(locate_one(episode_element, 'epno')).try(:downcase) == number.to_s.downcase
    end
  end

  def self.filter_anidb_episodes episode_elements, number_regexp
    episode_elements.select do |episode_element|
      !!element_text(locate_one(episode_element, 'epno')).try(:downcase).try(:match, number_regexp)
    end
  end

  def self.element_text element
    return nil unless element
    element.nodes.collect{ |e| e.respond_to?(:text) ? e.text : e.to_s }.compact.join(' ').strip
  end

  def self.parse_anidb_date text, path:

    date_string = text.to_s.strip
    return nil if date_string.blank?

    if match = date_string.match(/^\d{4}-\d{2}-\d{2}$/)
      Time.parse match[0]
    else
      scrap.warnings << "#{path} element is not in the expected YYYY-MM-DD format: #{date_string}"
      nil
    end
  end

  def self.anidb_text_to_markdown text
    return nil if text.blank?
    text.gsub(/\n{1}/, "\n\n").gsub(/(https?:\/\/[^\s]+) \[([^\[\]]+)\]/i, '[\2](\1)')
  end

  def self.anidb_image_url image
    return nil if image.blank?
    ANIDB_IMAGE_URL % { image: image }
  end

  def self.locate element, path, options = {}
    current_path = options[:current_path] || "/#{element.name}"
    result = Array.wrap(element.locate(path))

    n = result.length
    min = options[:min] || (options[:required] ? 1 : 0)
    max = options[:max]

    expected = if min && min == max
      "exactly #{min}"
    elsif min && max
      "#{min}-#{max}"
    elsif min
      "at least #{min}"
    elsif max
      "at most #{max}"
    end

    path = "#{current_path}/#{path}"
    raise "Expected to find #{expected} element(s) at path #{path}, got #{n}" if n < min || (max && n > max)

    result
  end

  def self.locate_one element, path, options = {}
    options[:max] = 1
    locate(element, path, options).first
  end

  def self.config
    Rails.application.service_config :anidb
  end
end
