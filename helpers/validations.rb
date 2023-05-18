############### users ################
def valid_new_password?(password_str)
  # regex with look aheads from https://stackoverflow.com/questions/11992544/validating-password-using-regex
  /^.*(?=.{10,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=!]).*$/ =~ password_str
end

def valid_credentials?(user_name, password)
  user_id, pw_hash = @storage.user_id_pw_hash(user_name)

  if user_id.nil?
    # TODO preserve user_name value, insert into sign in 
    session[:error] = "Could not find user \"#{user_name}\""
  else
    # check the password
    return user_id if BCrypt::Password.new(pw_hash) == password
    # at this point, only option is user_name exists, password doesn't match
    # TODO preserve UN and dummy string for pw placeholder
    session[:error] = "Incorrect password for user: #{user_name}"
  end
  false
end


############### data ##################

def valid_integer_string(str)
  str.to_i.to_s == str && str.to_i >= 0
end
 

############### forests ###############

def valid_forest_input?(name, description)
  valid_forest_name?(name)
  valid_forest_description?(description)
  @invalid_input.empty?
end

def valid_forest_name?(name)
  forest_names = forests_names_hash(@user_id)

  if name.size == 0
    @invalid_input.merge!({ forest_name: "Your forest name cannot be blank or whitespace only"})
  elsif forest_names.has_key?(name.downcase) && (forest_names[name.downcase] != @forest_id)
    @invalid_input.merge!({ forest_name: "A forest with the name \"#{name}\" already exists"})
  else 
    @valid_input[:forest_name] = name
    return true
  end
  false
end

def valid_forest_description?(description)

  if description.size == 0
    @invalid_input.merge!({ forest_description: "Your forest description cannot be blank or whitespace only"})
    #binding.pry
    #set_error("Your forest name cannot be blank or whitespace only")
    return false
  end
  @valid_input[:forest_description] = description
  true
end

################ sections ################

def valid_section_name?(name)
  name.strip!
  name.size > 0
end

def validate_section_name(forest_id)
  name = params["section_name"]
  section_names = @storage.sections_names_hash(forest_id)

  matching_id = section_name_exists?(name, forest_id)

  if section_names.has_key?(name.downcase) && section_names[name.downcase] != @section_id
    @invalid_input[:section_name] = "This forest already has a section with the name \"#{params["section_name"]}\""
  elsif !valid_section_name?(name)
    @invalid_input[:section_name] = "Section name cannot be blank"
  else
    @valid_input.merge!({ section_name: name })
  end
end

def valid_section_description(description)
  description.strip!
  description.size > 0
end

def section_name_exists?(name, forest_id)
  @storage.section_name_exists?(name, forest_id) 
end

def validate_section_input(forest_id)
  if params["acerage"].to_f > 0
    @valid_input.merge!({ acerage: params["acerage"].to_f })
  else
    @invalid_input[:acerage] = "Acerage must be a positive number"
  end

  validate_section_name(forest_id)

  if valid_section_description(params["section_description"])
    @valid_input.merge!({ section_description: params["section_description"] })
  else
    @invalid_input[:section_description] = "Section description cannot be blank"
  end

  impact_date = params["impact_date"].empty? ? nil : Date.parse(params["impact_date"])
  impact_status = !!(params["impacted"] == 'on')

  # assume the impact status determines the rest of the conditional flow re: impact_date
  @valid_input.merge!({ impacted: impact_status })

  validate_impact_date(impact_status, impact_date)
end

def validate_impact_date(impact_status, impact_date)
  forward_dated = if impact_date.nil?
                    false
                  else
                    impact_date > Date.today
                  end

  # at this point the date in and of itself is valid enough to retain
  @valid_input.merge!({ impact_date: impact_date })

  if forward_dated
    @invalid_input[:impact_date] = "Impact date cannot be forward dated"
  end

  # happy paths
  if (impact_status == false && impact_date.nil?) || (impact_status && !forward_dated)
    @valid_input.merge!({ impacted: impact_status, impact_date: impact_date })
  end

  # box checked with no date
  if (impact_status == true && impact_date.nil?)
    @invalid_input[:impact_date] = "Impact date must be set if Impacted box is checked"

  # date input set, box not checked
  elsif (impact_status == false && impact_date != nil)
    @invalid_input[:impact_date] = "Impact date must be cleared if Impacted box is not checked"
  end
end

############## generic 

def add_invalid_input_usage(input, usage_str)
  if session[:invalid_input]
    session[:invalid_input][input] = usage_str
  else
    session[:invalid_input] = { input => usage_str}
  end
end