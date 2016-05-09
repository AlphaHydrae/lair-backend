module SqlHelper
  def strip_sql sql
    sql.strip.gsub /\s+/, ' '
  end
end
