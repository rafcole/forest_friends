<div>
  <p><a href='/forests'>View all forests</a></p>
  <h2> Forest: <%= @forest_details[:forest_name] %> </h2>
  <div>
    <ul>
      <li>Sections: <%= @forest_details[:sections_total] %> </li>
      <li>Impacted sections: <%= @forest_details[:sections_impacted] %></li>
      <p>---------</p>
      <li>Acerage: <%= @forest_details[:acerage_total] %> </li>
      <li>Impacted acerage: <%= @forest_details[:acerage_impacted]%>
      <p>---------</p>
      <li>Description: <%== @forest_details[:forest_description]%> </li>
    </ul>
  </div>
  <p><a href='/forests/<%=@forest_id%>/edit'> Edit this forest </a></p>
</div>

<div>
  <h3><a href="/forests/<%=@forest_id%>/sections/create">Add a section to <%= @forest_details[:forest_name] %></a></h3>

  <h2>Sections</h2>

    
    <div>
      <% if @forest_sections.nil? %>
        <strong>There are no sections listed under this forest. 
       
      <% else %>

        <p>Sort by: <a href="<%=request.path_info%>">Name</a>, <a href='<%=request.path_info + '?sort_by=impacted'%>'> Impacted Status</a>
      
        <ul>
          <% @forest_sections.each do |section| %>
            <li><h3>Section: <%=section[:section_name]%></h3></li>
              <ul>
                <li><strong>Acerage:</strong> <%=section[:acerage]%></li>
                <li><strong>Status:</strong> <%=section[:impacted] ? "Impacted by fire" : "Not impacted" %></li>
                <% if section[:impacted] %>
                  <li><strong>Impact date:</strong> <%=section[:impact_date]%></li>
                <% end %>
                <li><strong>Description:</strong> <%=section[:section_description]%></li>
                <li><a href="/forests/<%=@forest_id%>/sections/<%=section[:id]%>/edit">Edit this section</a></li>
              </ul>
          <% end %>
        </ul>
      <% end %>
    </div>
</div>
<br>

<% # requires @previous_page_num, @next_page_num %>
<% # @page_range, @requested_page_number%>
<% unless @page_range.empty? %>
  <h3>Navigation</h3>
  <p><% unless @previous_page_num.nil? || @previous_page_num == 0 %>
      <% link = "?page=#{@previous_page_num}" %>
      <% link = link + "&sort_by=impacted" if params['sort_by'] == 'impacted' %>
      <a href="<%=link%>">
    <% end %>
      Previous Page</a>
      <% unless @forest_sections.nil? %>
        <% @page_range.each do |page_num| %>
          <% if page_num == @requested_page_number %>
            <strong><%=page_num%></strong>
          <% else %>
            <% link = "?page=#{page_num}" %>
            <% link = link + "&sort_by=impacted" if params['sort_by'] == 'impacted' %>
            <a href="<%=link%>"><%=page_num%></a>
          <% end %>
        <% end %> 
      <% end %>
      <% if @next_page_num %> 
        <% link = "?page=#{@next_page_num}" %>
        <% link = link + "&sort_by=impacted" if params['sort_by'] == 'impacted' %>
        <a href="<%=link%>">
      <% end %>
        Next Page</a>
  </p>
<% end %>
