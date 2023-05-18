def forest_details(user_id, forest_id)
  @storage.forest_details(user_id, forest_id)
end

def forest_agg_data(forest_id)
  @storage.forest_agg_data(forest_id)
end

def forest_exists?(forest_id)
  @storage.forest_exists?(forest_id)
end

def user_forests_page(user_id, page_num = 1, results_per_page = 2, sort_by = nil)
  @storage.user_forests_page(user_id, page_num, results_per_page, sort_by)
end

def create_forest(user_id, forest_name, forest_description)
  results = @storage.create_forest(user_id, forest_name, forest_description)

  if results.num_tuples == 0
    set_error("Forest not created, error in app#create_forest")
    redirect "/forests/create", { "forest_name" => forest_name, "forest_description" => forest_description }
  end
  
  hsh = { forest_id: results.tuple(0)["id"], forest_name: results.tuple(0)["name"] }
end

def delete_forest(manager_id, forest_id)
  @storage.delete_forest(manager_id, forest_id)
end

def edit_forest(manager_id, forest_id, hsh)
  hsh = { forest_name: hsh[:forest_name], 
          forest_description: hsh[:forest_description], 
          manager_id: manager_id, 
          forest_id: forest_id
        }

  # returns num rows updated, should be 0 or 1
  @storage.edit_forest(hsh)
end

def forest_sections_page(forest_id, page_num = 1, results_per_page = 4, sort_by = nil)
  @storage.forest_sections_page(forest_id, page_num, results_per_page, sort_by)
end

def forest_name(forest_id)
  @storage.forest_name(forest_id)
end

def forests_names_hash(user_id)
  # {"a5" => 4, "a7" => 98...}
  @storage.forests_names_hash(user_id)
end
