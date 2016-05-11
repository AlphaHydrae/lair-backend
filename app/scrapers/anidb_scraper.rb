class AnidbScraper < ApplicationScraper

  def self.scraps? *args
    config[:enabled] && super(*args)
  end

  def self.provider
    :anidb
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

    type_elements = root.locate('type')
    if type_elements.empty?
      raise "Could not find required /anime/type element"
    elsif type_elements.length >= 2
      raise "Found #{type_elements.length} /anime/type elements"
    end

    data_type = element_text type_elements.first
    if data_type != 'TV Series'
      raise "Unsupported AniDB data type #{data_type.inspect}"
    end

    work = find_or_build_work scrap

    data_language = Language.find_or_create_by! tag: 'en'
    anidb_default_language = Language.find_or_create_by! tag: 'ja'

    work.language = anidb_default_language

    start_date = parse_date element_text(locate_one(root, 'startdate'))
    work.start_year = start_date.try(:year)

    end_date = parse_date element_text(locate_one(root, 'enddate'))
    work.end_year = end_date.try(:year)

    work.number_of_items = element_text(locate_one(root, 'episodecount')).try(:to_i)

    title_elements = locate root, 'titles/title', min: 1
    add_titles work: work, title_elements: title_elements

    description = parse_anidb_text element_text(locate_one(root, 'description'))
    add_work_description scrap: scrap, work: work, description: description, language: data_language

    image = element_text locate_one(root, 'picture')
    if image.present? && work.image.blank?
      work.build_image.url = anidb_image_url image
    end

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

    # TODO: parse episodes

    raise "Not yet supported"
  end

  private

  ANIDB_URL = 'http://api.anidb.net:9001/httpapi?request=anime&client=%{client_id}&clientver=%{client_version}&protover=1&aid=%{anime_id}'
  ANIDB_IMAGE_URL = 'http://img7.anidb.net/pics/anime/%{image}'

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

    title_data = title_elements.inject([]) do |memo,title_element|

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

      if match = full_name.match(/^\w+$/)
        pseudonym = full_name
      elsif match = full_name.match(/^(\w+) (\w+)$/i)
        first_names = match[1]
        last_name = match[0]
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

  def self.element_text element
    return nil unless element
    element.nodes.collect{ |e| e.respond_to?(:text) ? e.text : e.to_s }.compact.join(' ').strip
  end

  def self.parse_date text

    date_string = text.to_s.strip
    return nil if date_string.blank?

    if match = date_string.match(/^\d{4}-\d{2}-\d{2}$/)
      Time.parse match[0]
    else
      scrap.warnings << "The /anime/startdate element is not in the expected YYYY-MM-DD format: #{date_string}"
      nil
    end
  end

  def self.parse_anidb_text text
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
    Rails.application.service_config(:anidb).with_indifferent_access
  end
end
