def sign_in(user_name, user_id)
  session[:user] = { name: user_name, id: user_id }
end

def sign_out
  session.delete(:user)
end

def require_signed_in_user
  if session[:user].nil?
    session[:attempted_access_path] = request.fullpath
    session[:error] = "You must be logged in to access \"#{request.fullpath}\""
    redirect "/signin"
  end
end

def has_access?(user_id, entity_id, entity_type)
  if entity_type == :section
    @storage.validate_section_user(user_id, entity_id)
  elsif entity_type == :forest
    @storage.validate_forest_user(user_id, entity_id)
  end
end

