module SpecExpectationsHelper
  MODELS = [ Item, ItemDescription, ItemLink, ItemPart, ItemPerson, ItemTitle, Language, Ownership, Person, User ]

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
  end

  def with_api_id expectation, length = 12
    if expectation.kind_of? Array
      expectation.collect{ |e| with_api_id e, length }
    else
      expectation.merge(id: /\A[a-z0-9]{#{length}}\Z/)
    end
  end

  def expect_changes changes = {}, &block
    expect_changes_recursive(changes, MODELS, &block)
  end

  def expect_no_changes &block
    expect_changes &block
  end

  private

  def expect_changes_recursive changes, models, &block
    if models.empty?
      block.call
    else
      model = models.shift
      change = changes[model] || changes[model.name.underscore.pluralize.to_sym] || changes[model.name.underscore.to_sym] || 0
      expect{ expect_changes_recursive(changes, models, &block) }.to change(model, :count).by(change), "expected #{model} count to change by #{change}"
    end
  end
end
