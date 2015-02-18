RSpec::Matchers.define :have_db_columns do |*expected|
  match do |actual|

    @model = actual.kind_of?(ActiveRecord::Base) ? actual.class : actual
    @actual_columns = @model.columns.collect(&:name).collect(&:to_s).sort
    expected_columns = expected.collect(&:to_s).sort

    @missing_columns = (expected_columns - @actual_columns).sort
    @extra_columns = (@actual_columns - expected_columns).sort

    @actual_columns.sort == expected_columns
  end

  failure_message do |actual|
    "expected that #{@model} would have database columns #{expected.join(', ')} but actual columns where #{@actual_columns.join(', ')} (columns #{@missing_columns.join(', ')} are missing, columns #{@extra_columns.join(', ')} are extra)"
  end
end
