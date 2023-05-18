def section_details(section_id)
  # query database
  @storage.section_details(section_id)
end

def section_name(section_id)
  @storage.section_name(section_id)[0]
end

def create_section(forest_id, hsh)
  @storage.create_section(forest_id, hsh)
end

def delete_section(section_id)
  @storage.delete_section(section_id)
end

def update_section(hsh)
  @storage.edit_section(hsh)
end
