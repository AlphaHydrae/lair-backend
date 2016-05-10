module ApiPaginationHelper
  def paginated rel, options = {}

    offset = params[:start].to_i
    offset = 0 if offset < 1

    limit = params[:number].to_i
    limit = options.fetch :default_number, 15 if limit < 1
    limit = 0 if params[:number] == '0'

    header 'X-Pagination-Start', offset.to_s
    header 'X-Pagination-Number', limit.to_s

    total_count = @pagination_total_count || rel.count
    header 'X-Pagination-Total', total_count.to_s

    filtered_count = 0

    filtered_rel = if block_given?
      yield rel
    else
      rel
    end

    filtered_count = if @pagination_filtered_count
      @pagination_filtered_count
    elsif @pagination_filtered_count_rel
      @pagination_filtered_count_rel.count
    elsif filtered_rel != rel
      filtered_rel.count
    else
      total_count
    end

    header 'X-Pagination-Filtered-Total', filtered_count.to_s

    filtered_rel = filtered_rel.none if limit == 0

    filtered_rel.offset(offset).limit(limit)
  end
end
