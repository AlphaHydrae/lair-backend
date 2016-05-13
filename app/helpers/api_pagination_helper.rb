module ApiPaginationHelper
  def paginated rel, options = {}

    offset = params[:start].to_i
    offset = 0 if offset < 1

    limit = params[:number].to_i
    limit = options.fetch :default_number, 15 if limit < 1

    header 'X-Pagination-Start', offset.to_s
    header 'X-Pagination-Number', limit.to_s
    header 'X-Pagination-Total', rel.count.to_s

    filtered_rel = if block_given?
      yield rel
    else
      rel
    end

    if filtered_rel != rel

      filtered_count = if @pagination_filtered_count
        @pagination_filtered_count
      else
        (@pagination_filtered_count_rel || filtered_rel).count
      end

      header 'X-Pagination-Filtered-Total', filtered_count.to_s
    end

    filtered_rel.offset(offset).limit(limit)
  end
end
