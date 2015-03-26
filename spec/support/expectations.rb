module SpecExpectationsHelper
  MODELS = [ Event, Image, ImageSearch, Item, ItemDescription, ItemLink, ItemPart, ItemPerson, ItemTitle, Language, Ownership, Person, User ]

  def expect_json expected, path = '', actual = nil
    json = path.empty? ? JSON.parse(response.body) : actual

    if expected.kind_of? Hash
      expect(json).to be_a_kind_of(Hash)
      expect(json.keys).to match_array(expected.keys.collect(&:to_s))
      expected.each_pair do |k,v|
        expect_json v, "#{path}/#{k}", json[k.to_s]
      end
    elsif expected.kind_of? Array
      expect(json).to be_a_kind_of(Array)
      expect(json).to have(expected.length).items
      expected.each.with_index do |v,i|
        expect_json v, "#{path}/#{i}", json[i]
      end
    elsif expected.kind_of? Regexp
      expect(json).to be_a_kind_of(String)
      expect(json).to match(expected)
    elsif expected == !!expected # boolean
      expect(json).to be(expected)
    else
      expect(json).to eq(expected)
    end

    json
  end

  def with_api_id expectation, length = 12
    if expectation.kind_of? Array
      expectation.collect{ |e| with_api_id e, length }
    elsif expectation.kind_of? Hash
      expectation.merge(id: /\A[a-z0-9]{#{length}}\Z/)
    else
      raise "Array or Hash required"
    end
  end

  def expect_changes changes = {}, &block

    before_counts = MODELS.collect &:count
    block.call
    after_counts = MODELS.collect &:count

    MODELS.each.with_index do |model,i|
      expected_change = changes[model] || changes[model.name.underscore.pluralize.to_sym] || changes[model.name.underscore.to_sym] || 0
      expect(after_counts[i]).to eq(before_counts[i] + expected_change), ->{ "expected #{model} count to change by #{expected_change}, but it changed by #{after_counts[i] - before_counts[i]}" }
    end
  end

  def expect_no_changes &block
    expect_changes &block
  end
end
