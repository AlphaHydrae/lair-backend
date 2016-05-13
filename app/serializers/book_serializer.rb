class BookSerializer < ItemPartSerializer
  def build json, options = {}
    super json, options
    json.publisher record.publisher if record.publisher
    json.isbn record.isbn if record.isbn
  end
end
