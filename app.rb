#! /usr/bin/env ruby

require "sinatra"
require "tilt/erubis"
require "bcrypt"
require "date"

# todo - change name if custom class name is different from "database"
require_relative "classes/database.rb" 
require_relative "helpers/validations.rb"
require_relative "helpers/sign_in.rb"
require_relative "helpers/pagination.rb"
require_relative "helpers/forest_crud.rb"
require_relative "helpers/section_crud.rb"


# include pagination

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end


#    _    _ ______ _      _____  ______ _____   _____ 
#   | |  | |  ____| |    |  __ \|  ____|  __ \ / ____|
#   | |__| | |__  | |    | |__) | |__  | |__) | (___  
#   |  __  |  __| | |    |  ___/|  __| |  _  / \___ \ 
#   | |  | | |____| |____| |    | |____| | \ \ ____) |
#   |_|  |_|______|______|_|    |______|_|  \_\_____/


helpers do 

  def set_error(str)
    session[:error] = "Error: #{str}"
  end
  
  def set_success(str)
    session[:success] = "Success: #{str}"
  end

  def user_overview(user_id)
    @storage.user_overview(user_id)
  end
end


  # ███████ ██ ██      ████████ ███████ ██████  ███████ 
  # ██      ██ ██         ██    ██      ██   ██ ██      
  # █████   ██ ██         ██    █████   ██████  ███████ 
  # ██      ██ ██         ██    ██      ██   ██      ██ 
  # ██      ██ ███████    ██    ███████ ██   ██ ███████ 



before do
  @storage = ForestFriendsDatabase.new(logger)
end

after do 
  @storage.disconnect
end


    # ██████   ██████  ██    ██ ████████ ███████ ███████ 
    # ██   ██ ██    ██ ██    ██    ██    ██      ██      
    # ██████  ██    ██ ██    ██    ██    █████   ███████ 
    # ██   ██ ██    ██ ██    ██    ██    ██           ██ 
    # ██   ██  ██████   ██████     ██    ███████ ███████ 


# homepage
get "/" do
  require_signed_in_user
  @user_name = session[:user][:name]
  @user_id = session[:user][:id]
  @overview = user_overview(@user_id)

  erb :home
end

################################### SIGN IN SIGN OUT ###################################
# sign in
get "/signin" do 
  if session[:user]
    session[:message] = <<~MSG
                          You are currently signed in as #{session[:user][:name]}. 
                          <a href=/signout> Click here to signout</a>
                          or enter credentials below to be logged in as a different user
                        MSG
  end

  erb :signin
end

# submit sign in data
post "/signin" do
  # log out current user, in case logged in user signing in as different user
  session.delete(:user)

  user_name = params["username"]
  password = params["password"]

  user_id = valid_credentials?(user_name, password)

  # if the password is correct, allow log in
  if user_id
    sign_in(user_name, user_id)
    session[:success] = "Welcome #{user_name}"

    if session[:attempted_access_path]
      redirect session.delete(:attempted_access_path)
    else
      redirect "/"
    end
  end

  mock_password = '-' * password.length

  erb :signin, username: user_name, password: mock_password
end

# sign out
# should probably be post
get "/signout" do
  session.delete(:user)
  session[:success] = "You have been logged out"

  redirect "/signin"
end

# view all forests
get "/forests" do 
  require_signed_in_user
  @user_id = session[:user][:id]

  @requested_page_number = page_param_validation()
  @results_per_page = 5

  @num_user_forests_pages = num_user_forests_pages(@user_id, @results_per_page)

  # if the number of total pages = 0, don't run query
  if @num_user_forests_pages == 0
    # handle no results found in the erb
    erb :forests
  elsif @num_user_forests_pages < @requested_page_number
    # edge case of wierd input to page query param
    session[:error] = "Insufficient results to display page #\"#{@requested_page_number}\""
    redirect "/forests"
  # if the requested page number is out of range
    # error and redirect
  else
    prev_next_page_nums(@num_user_forests_pages, @requested_page_number)

    @page_range = pagination_range(@requested_page_number, @num_user_forests_pages)

    @sort_by = params['sort_by']

    @user_forests = user_forests_page(@user_id, @requested_page_number, @results_per_page, @sort_by)
    erb :forests
  end
end

# edit input for one specific forest
# effectively the "display all" for sections of that forest?
get "/forests/:id/edit" do  |forest_id|
  @forest_id = forest_id
  require_signed_in_user
  user_id = session[:user][:id]

  @valid_input = forest_details(user_id, @forest_id)
  @invalid_input = {}

  if user_id != @valid_input[:manager_id]
    set_error("You do not have permission to access this forest")
    redirect "/"
  end

  erb :forest_edit
end

# submit forest edits
post "/forests/:id/edit" do  |forest_id|
  require_signed_in_user
  @user_id = session[:user][:id]

  @forest_id = forest_id

  @valid_input = forest_details(@user_id, @forest_id)
  @invalid_input = {}

  forest_name = params['forest_name'].strip
  forest_description = params['forest_description'].strip
  
  # @valid_input and @invalid_input are both modified by
  # predicate validation #valid_forest_input?(), seems inappropriate
  unless valid_forest_input?(forest_name, forest_description)
    set_error("An error has occured with your input, please see below")
    puts "___________ @invalid_input = #{@invalid_input}"
    erb :forest_edit
  else
    edit_forest(@user_id, @forest_id, @valid_input)
    set_success("Changes saved to #{params["forest_name"]}")
    redirect "/forests/#{forest_id}"
  end
end


# delete forest
post "/forests/:id/delete" do |forest_id|
  require_signed_in_user

  forest_name = forest_name(forest_id)
  if delete_forest(session[:user][:id], forest_id) == 0
    # this leans heavily on the return value of rows impacted
    # by the sql query, not abstracted enough
    set_error("Forest not deleted. You do not have access to this forest")
    redirect "/"
  else
    set_success("Forest \"#{forest_name}\" deleted")
    redirect "/forests"
  end
end 

# input new forest
get "/forests/create" do 
  require_signed_in_user
  
  erb :forest_create
end

# validate and create forest in db
post "/forests/create" do
  require_signed_in_user
  @user_id = session[:user][:id]
  @forest_id = nil
  
  forest_name = params['forest_name'].strip
  forest_description = params['forest_description'].strip

  @valid_input = {}
  @invalid_input = {}

  valid_forest_input?(forest_name, forest_description)
  if @invalid_input.empty? 
    hsh = create_forest(session[:user][:id], forest_name, forest_description)
    set_success("Forest #{hsh[:forest_name]} successfully created")
    redirect "/forests/#{hsh[:forest_id]}"
  end

  set_error("Invalid input, please see details below")
  erb :forest_create
end

# view a single forest plus its sections
get "/forests/:id" do |forest_id|
  require_signed_in_user
  @user_id = session[:user][:id]

  unless forest_exists?(forest_id)
    set_error("\"#{forest_id}\" is not a valid forest")
    redirect "/forests"
  end

  @forest_id = forest_id
  @forest_details = forest_agg_data(@forest_id)
  @total_sections = @forest_details[:sections_total]

  if @forest_details[:manager_id] != @user_id
    set_error("You do not have access to this forest")
    redirect "/"
  end

  @requested_page_number = page_param_validation()
  @results_per_page = 4

  @total_pages = num_pages(@total_sections, @results_per_page)
  @page_range = pagination_range(@requested_page_number, @total_pages)
  @sort_by = params['sort_by']

  prev_next_page_nums(@total_pages, @requested_page_number)

  if @total_sections == 0
    # no need to run the rest of the code
    erb :forest_view
  elsif @total_pages < @requested_page_number
    session[:error] = "Insufficient results to display page #\"#{@requested_page_number}\""
    redirect "/forests/#{forest_id}"
  else

    # array of hashes
    @forest_sections = forest_sections_page(@forest_id, @requested_page_number, @results_per_page, @sort_by)
    erb :forest_view
  end
end


# view single section
get "/forests/:forest_id/sections/:section_id/edit" do |forest_id, section_id|
  require_signed_in_user
  @user_id = session[:user][:id]

  @forest_id = forest_id
  @section_id = section_id

  # make sure user has permission to edit
  if !has_access?(@user_id, section_id, :section)
    set_error("You do not have access to this section")
    redirect "/"
  end

  @valid_input = section_details(@section_id)
  @invalid_input = {}

  erb :section_edit
end


post "/forests/:forest_id/sections/:section_id/edit" do |forest_id, section_id|
  require_signed_in_user
  @user_id = session[:user][:id]

  @forest_id = forest_id
  @section_id = section_id

  if !has_access?(@user_id, section_id, :section)
    set_error("You do not have access to that section")
    redirect "/"
  end

  @valid_input = section_details(section_id)
  @invalid_input = {}

  validate_section_input(forest_id)

  if @invalid_input.empty?
    # add info necessary for #update_section
    @valid_input.merge!({ id: section_id, forest_id: forest_id })
    # light is green, the trap is clean

    # at this point [:valid_input] is single source of truth
    # needs to have all necessary inputs for update_section()
    update_section(@valid_input)
    set_success("Section updated successfully")
    redirect "/forests/#{forest_id}/sections/#{section_id}"
  end

  set_error("Invalid input, please see below")
  erb :section_edit
end

# create new section
get "/forests/:forest_id/sections/create" do |forest_id|
  @forest_id = forest_id
  require_signed_in_user
  @user_id = session[:user][:id]

  @valid_input, @invalid_input = {}, {}

  erb :section_create
end

# view single section
get "/forests/:forest_id/sections/:section_id" do |forest_id, section_id|
  require_signed_in_user
  @user_id = session[:user][:id]


  if !has_access?(@user_id, section_id, :section)
    set_error("Section \"#{section_id}\" does not exist or you do not have access to it")
    redirect "/forests/#{forest_id}"
  end

  @forest_id = forest_id
  @forest_name = forest_name(@forest_id)
  @section_id = section_id
  @section = @storage.section_details(@section_id)

  erb :section_view
end

# submit new section
post "/forests/:forest_id/sections/create" do |forest_id|
  # section id inst. var is for name validation
  @section_id = nil
  @forest_id = forest_id
  require_signed_in_user
  @user_id = session[:user][:id]

  if !has_access?(@user_id, forest_id, :forest)
    set_error("You do not have access to this forest")
    redirect "/"
  end

  # validate user
  @valid_input, @invalid_input = {}, {}
  validate_section_input(forest_id)

  if @invalid_input.empty?
    @valid_input.merge!({ forest_id: forest_id })

    section_id = create_section(@forest_id, @valid_input)
    set_success("Section created successfully")

    redirect "/forests/#{@forest_id}/sections/#{section_id}"
  else
    set_error("Invalid input, please see below")
    erb :section_create
  end
end

# delete a section
post "/forests/:forest_id/sections/:section_id/delete" do |forest_id, section_id|
  require_signed_in_user
  @user_id = session[:user][:id]

  details = section_details(section_id)

  if details.nil?
    set_error("The requested section could not be found")
    redirect "/forests/#{forest_id}"
  elsif details[:manager_id] != @user_id
    set_error("You do not have access to this forest")
    redirect "/"
  else
    set_success("Section: \"#{details[:section_name]}\" has been deleted")
    delete_section(section_id)
    redirect "/forests/#{forest_id}"
  end
end

not_found do
  set_error('Requested page could not be found')
  redirect "/"
end