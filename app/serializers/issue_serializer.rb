class IssueSerializer < ItemSerializer
  def build json, options = {}
    super json, options
    json.publisher record.publisher if record.publisher
    json.issn record.issn if record.issn
  end
end
