require 'pg'

class ForestFriendsDatabase

  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "forest_friends")
    end

    @logger = logger
  end

  def disconnect
    @db.close
  end

  def validate_forest_user(user_id, forest_id)
    sql = "SELECT id FROM forests WHERE manager_id = $1 AND id = $2"

    query(sql, user_id, forest_id).num_tuples == 1
  end

  def validate_section_user(user_id, section_id)
    sql = <<~SQL
            SELECT manager_id FROM forests
            JOIN sections ON sections.forest_id = forests.id
            WHERE sections.id = $1 AND forests.manager_id = $2
          SQL

    query(sql, section_id, user_id).num_tuples == 1
  end

    # return hash for displaying data about sections of SINGLE forest
  def forest_agg_data(forest_id)
    sql = <<~SQL
            SELECT 
            forests.manager_id,
            forests.id AS forest_id,
            forests.name AS forest_name,
            forests.description AS forest_description,
            count(sections.id) AS sections_total,
            count(sections.impacted) filter (where sections.impacted) 
              AS sections_impacted,
            sum(sections.acerage) 
              AS acerage_total,
            sum(sections.acerage) filter (where sections.impacted) 
              AS acerage_impacted
            FROM forests
            LEFT JOIN sections ON forests.id = sections.forest_id
            WHERE forests.id = $1
            GROUP BY forests.id, forests.name, forests.description;
          SQL
    
    results = query(sql, forest_id).tuple(0)

    { 
      acerage_total: results['acerage_total'].to_f,
      acerage_impacted: results['acerage_impacted'].to_f,
      forest_id: forest_id,
      forest_name: results['forest_name'],
      forest_description: results['forest_description'],
      manager_id: results['manager_id'],
      sections_total: results['sections_total'].to_i,
      sections_impacted: results['sections_impacted'].to_i
    }
  end

  def create_section(forest_id, hsh)
    sql = <<~SQL
            INSERT INTO
              sections(forest_id, name, description, acerage, impacted, impact_date)
            VALUES
                      ($1       , $2  , $3         , $4     , $5      , $6)
            RETURNING id;
          SQL
    query(sql,
          forest_id,
          hsh[:section_name],
          hsh[:section_description],
          hsh[:acerage],
          hsh[:impacted],
          hsh[:impact_date]).tuple(0)["id"]
  end

  def user_forests_page(user_id, page_num, results_per_page, sort_by)
    offset = results_per_page * (page_num - 1)

    sql = <<~SQL
              SELECT 
              forests.manager_id,
              forests.id AS forest_id,
              forests.name AS forest_name,
              forests.description AS forest_description,
              count(sections.id) AS sections_total,
              count(sections.impacted)
                AS sections_impacted,
              sum(sections.acerage) 
                AS acerage_total,
              sum(sections.acerage) filter (where sections.impacted)
                AS acerage_impacted
              FROM forests
              FULL OUTER JOIN sections ON forests.id = sections.forest_id
              WHERE manager_id = $1
              GROUP BY forests.id, forests.name, forests.description
          SQL

    order_by = if sort_by == "impacted" 
                 " ORDER BY ((sum(sections.acerage) filter (where sections.impacted)) > 0) DESC NULLS LAST, UPPER(forests.name) ASC LIMIT $2 OFFSET $3;"
                else
                 " ORDER BY UPPER(forests.name) ASC LIMIT $2 OFFSET $3;"
               end

    sql = sql + order_by

    results = query(sql, user_id, results_per_page, offset)
    
    #results = query(sql, user_id, results_per_page, offset)
    # format to hash to hand off to application
    #return nil if results.num_tuples == 0
    create_forests_hash(results)
  end

  def forest_sections_page(forest_id, page_num, results_per_page, sort_by)
    offset = results_per_page * (page_num - 1)

    sql = <<~SQL
            SELECT id,
                   forest_id,
                   acerage,
                   name AS section_name,
                   description AS section_description,
                   impacted,
                   impact_date
            FROM sections WHERE forest_id = $1
          SQL

    order_by = if sort_by == "impacted" 
              " ORDER BY impacted DESC, UPPER(sections.name) ASC LIMIT $2 OFFSET $3;"
            else
              " ORDER BY UPPER(sections.name) ASC LIMIT $2 OFFSET $3;"
            end

    sql = sql + order_by

    results = query(sql, forest_id, results_per_page, offset)
    # format to hash to hand off to application
    #return nil if results.num_tuples == 0
    create_sections_arr(results)
  end

  def forest_name(id)
    sql = "SELECT name FROM forests WHERE id = $1"
    query(sql, id).tuple(0)['name']
  end

  def num_user_forests(user_id)
    sql = <<~SQL
            SELECT count(id) AS num_results FROM forests WHERE manager_id = $1
          SQL

    results = query(sql, user_id)
    results.tuple(0)['num_results'].to_i
  end

  def forest_details(user_id, forest_id)
    sql = <<~SQL
            SELECT
              id as forest_id,
              name as forest_name,
              description as forest_description,
              manager_id
            FROM forests WHERE id = $1 AND manager_id = $2;
            
          SQL

    results = query(sql, forest_id, user_id)
    # either no matches on the forest id or the manager id wasn't a match
    return nil if results.ntuples == 0 
    create_forests_hash(results)[0]
  end

  # returns hash with forest_id and manager_id for validation purposes
  def forest_exists?(forest_id)
    sql = "SELECT * FROM forests WHERE id = $1"
    results = query(sql, forest_id)

    if results.num_tuples != 1
      return false
    else
      results.tuple(0)['manager_id'].to_i
    end
  end

  def create_forest(user_id, name, description)
    sql = <<~SQL
            INSERT INTO forests(manager_id, name, description)
            VALUES($1, $2, $3)
            RETURNING id, name;
          SQL

    query(sql, user_id, name, description)
  end

  def forest_name_exists?(name, id = nil)
    sql = <<~SQL
            SELECT * FROM forests WHERE name = $1;
          SQL
    
    query(sql, name).ntuples > 0
  end

  def section_name_exists?(name, forest_id)
    sql = <<~SQL
            SELECT * FROM sections WHERE name = $1 AND forest_id = $2;
          SQL
    
    results = query(sql, name, forest_id)

    if results.ntuples > 0
      results.tuple(0)["id"]
    else
      false
    end
  end

  def forests_names_hash(user_id)
    sql = <<~SQL
            SELECT name, id FROM forests WHERE manager_id = $1
          SQL
    
    results = query(sql, user_id)
    
    results.each_with_object({}) do |tuple, hsh|
      hsh.merge!({tuple["name"].downcase => tuple["id"].to_i}) 
    end
  end

  def sections_names_hash(forest_id)
    sql = <<~SQL
            SELECT name, id 
            FROM sections
            WHERE forest_id = $1
          SQL

    query(sql, forest_id).each_with_object({}) do |tuple, hsh|
      hsh.merge!({tuple["name"].downcase => tuple["id"].to_i}) 
    end
  end

  def edit_forest(hsh)
    sql = <<~SQL
            UPDATE forests SET name = $1, description = $2
            WHERE id = $3 AND manager_id = $4;
          SQL

    # needs begin/rescue block
    results = query(sql, hsh[:forest_name], hsh[:forest_description], hsh[:forest_id], hsh[:manager_id])

    results.cmdtuples # returns num rows impacted
  end

  def edit_section(hsh)
    sql = <<~SQL
            UPDATE sections SET
              forest_id = $1,
              acerage = $2,
              name = $3,
              description = $4,
              impacted = $5,
              impact_date = $6
            WHERE id = $7;
          SQL
    
    inputs = [ 
               hsh[:forest_id],
               hsh[:acerage], 
               hsh[:section_name], 
               hsh[:section_description], 
               hsh[:impacted], 
               hsh[:impact_date],
               hsh[:id]
              ]

    results = query(sql, *inputs)
    results.cmdtuples 
  end

  def delete_forest(manager_id, forest_id)
    sql = <<~SQL
            DELETE FROM forests
            WHERE id = $1 AND manager_id = $2
          SQL
    results = query(sql, forest_id, manager_id)
    results.cmdtuples
  end

  # refactor: roll this into user_forests_page
  def valid_forest_page?(user_id, page_num, results_per_page)
    offset = results_per_page * page_num
    sql = <<~SQL
            SELECT count(id) AS num_results FROM forests WHERE manager_id = $1
            LIMIT $2 OFFSET $3
          SQL
    results = query(sql, user_id, results_per_page, offset)
    results.tuple(1)['num_results'].to_i > 0
  end

  # return hash for displaying data about forests of a single manager
  # replaces other query that doesn't have agg data
  def much_more_forest_detail_per_mgr(manager_id)
    sql = <<~SQL
      SELECT 
      forests.manager_id,
      forests.id AS forest_id,
      forests.name AS forest_name,
      forests.description AS forest_description,
      count(sections.id) AS sections_total,
      count(sections.impacted) filter (where not sections.impacted) 
        AS sections_impacted,
      sum(sections.acerage) 
        AS acerage_total,
      sum(sections.acerage) filter (where not sections.impacted) 
        AS acerage_impacted
      FROM forests
      JOIN sections ON forests.id = sections.forest_id
      WHERE forests.manager_id = $1
      GROUP BY forests.id, forests.name, forests.description;
    SQL

    results = query(sql, manager_id)

    #{ big beautiful hash }
  end

  # where does the hashing happen? Fewest jumps possible indicate to do it in the app
  def add_user(user_name, password_hash)
  end

  def user_overview(user_id)
    sql = <<~SQL
            SELECT
            count(forests.id) AS user_forests_total,
            sum(sections.acerage) AS user_acerage_total, 
            sum(sections.acerage) filter(where not sections.impacted) AS user_acerage_impacted
            FROM forests
            JOIN sections ON forests.id = sections.forest_id
            WHERE forests.manager_id = $1;
          SQL

    user_overview_hash(query(sql, user_id))
  end

  def user_overview_hash(results)
    return nil if results.num_tuples == 0

    results = results.tuple(0)

    {
      user_forests_total: results["user_forests_total"],
      user_acerage_total: results["user_acerage_total"],
      user_acerage_impacted: results["user_acerage_impacted"]
    }
  end

  # returns BCrypt if user exists
  # returns nil if no such user
  def user_id_pw_hash(user_name)
    sql = "SELECT id, password FROM managers WHERE user_name = $1"
    results = query(sql, user_name)

    if results.values.empty?
      return nil
    else
      results.values[0]
    end
  end

  def section_details(section_id)
    sql = <<~SQL
            SELECT sections.id,
                   sections.forest_id,
                   sections.acerage,
                   sections.name as section_name,
                   sections.description as section_description,
                   sections.impacted,
                   sections.impact_date,
                   forests.manager_id 
            FROM sections
            JOIN forests ON sections.forest_id = forests.id
            WHERE sections.id = $1;
          SQL
    # all section data plus forest_id, plus manager_id
    # 9/14 added square bracket notation to return only one hash
    results = create_sections_arr(query(sql, section_id))[0]

    results
  end

  def section_name(section_id)
    sql = "SELECT name FROM sections WHERE id = $1"
    query(sql, section_id).values[0]
  end
  # delete a section
  # returns false if number of rows impacted is other than 1
  def delete_section(section_id)
    sql = "DELETE FROM sections WHERE id = $1"
    query(sql, section_id).cmdtuples == 1
  end

  private

  # array of hashes usable by application
  #[{id: 1, name: 'Olympic National forest'...}, {id:2...}]
  def create_forests_hash(query)
    query.map do |tuple|
      {
        id: tuple['forest_id'],
        manager_id: tuple['manager_id'],
        forest_name: tuple['forest_name'],
        forest_description: tuple['forest_description'],
        acerage_total: tuple['acerage_total'].to_f,
        acerage_impacted: tuple['acerage_impacted'].to_f,
        sections_total: tuple['sections_total'].to_i,
        sections_impacted:tuple['sections_impacted'].to_i
      }
    end
  end

  # array of hashes, one per section/tuple
  def create_sections_arr(results)
    results.map do |tuple|
      {
        id: tuple['id'],
        forest_id: tuple['forest_id'],
        manager_id: tuple['manager_id'],
        section_name: tuple['section_name'],
        section_description: tuple['section_description'],
        acerage: tuple['acerage'].to_f,
        impacted: tuple['impacted'] == 't',
        impact_date: tuple['impact_date']
      }
    end
  end
  
  def query(sql, *params)
    @logger.info("#{sql}: #{params}")
    @db.exec_params(sql, params)
  end
end