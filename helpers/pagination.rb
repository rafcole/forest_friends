
def pagination_range(current_page, total_pages)
  pages = []
  ((current_page - 4)..(current_page + 4)).each do |page_num|
    # skip out of range
    next if (page_num < 1) || (page_num > total_pages) || (page_num > (current_page + 2)) || (page_num < (current_page - 2))
    pages << page_num
  end 
  pages
end

  # [previous_page_num, next_page_num] for double assignment pattern
  def prev_next_page_nums(total_pages, current_page)
    @previous_page_num = current_page > 1 ? current_page - 1 : nil
    @next_page_num = current_page < total_pages ? current_page + 1 : nil
  end

  # validates the string input only
  # does not query database or validate results
  def page_param_validation
    page = params['page']
  
    # no input because wanted first results page
    if page.nil?
      return 1
  
    # non-integer or requests for page zero
    elsif page.to_i == 0
      # <%== for HTML sanitation used in layout.erb, interpolation ok
      set_error("Page \"#{page}\" could not be generated")
      redirect request.path_info 
    end
  
    # valid input
    page.to_i
  end

  # TODO: refactor to combine with #num_pages, redundant
  def num_user_forests_pages(user_id, results_per_page)
    num_results = @storage.num_user_forests(user_id)
  
    complete_pages = num_results / results_per_page
    incomplete_pages = ((num_results % results_per_page) > 0) ? 1 : 0
  
    complete_pages + incomplete_pages
  end

  def num_pages(num_results, results_per_page)
    complete_pages = num_results / results_per_page
    incomplete_pages = ((num_results % results_per_page) > 0) ? 1 : 0
  
    complete_pages + incomplete_pages
  end