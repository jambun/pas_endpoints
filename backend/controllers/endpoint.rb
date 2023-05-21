class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/endpoints')
    .description("Endpoint documentation")
    .params(["uri", String, "URI", :optional => true],
            ["method", String, "Method", :optional => true])
    .permissions([])
    .returns([200, "Endpoint doco"]) \
  do
    if params.has_key?(:uri)
      json_response(ArchivesSpaceService::Endpoint.all.select { |e|
                      e[:uri] == params[:uri] && (params.has_key?(:method) ? e[:method].include?(params[:method].intern) : true)
                    })
    else
      json_response(ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}.map{ |e| e[:uri] })
    end
  end


  Endpoint.get('/stub/:model')
    .description("Get a stub record for a JSONModel")
    .params(["model", String, "JSONModel to stub"],
            ['repo_id', Integer, "Repository id", :optional => true],
            ["expand", [String], "Properties to expand even if not required", :optional => true])
    .permissions([])
    .returns([200, "JSONModel(model)"],
             [404, "Model not found"]) \
  do
    model = params[:model]
    if models.has_key? model
      json_response( JSONModel(model.to_sym).stub(:repo_id => params[:repo_id], :expand => params.fetch(:expand) { [] }) )
    else
      raise NotFoundException.new
    end
  end


  Endpoint.get('/users/byusername/:username')
    .description("Get a user by username")
    .params(["username", String, "Username to get user for"])
    .permissions([:manage_users])
    .returns([200, "JSONModel(:user)"],
             [404, "User not found"]) \
  do
    user = User.find(:username => params[:username])

    raise NotFoundException.new if user.nil?

    json = User.to_jsonmodel(user)
    json.permissions = user.permissions

    json_response(json)
  end


  Endpoint.get('/pas/enumerations')
    .description("List enumerations without nested enumeration_values")
    .params()
    .permissions([])
    .returns([200, "[(:enumeration)]"]) \
  do
    enums = Enumeration.sequel_to_jsonmodel(Enumeration.all)
    enums.map do |e|
      eh = e.to_hash
      eh.delete('enumeration_values')
      eh['value_translations'] = Hash[eh['values'].map{|v| [v, I18n.t('enumerations.' + eh['name'] + '.' + v, :default => '[no translation]')]}]
      eh
    end
    json_response(enums)
  end


  Endpoint.get('/pas/schemas')
    .description("Get all ArchivesSpace schemas")
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (schemas)"]) \
  do
    schemas = Hash[ models.keys.map { |schema|
                      s = JSONModel(schema.to_sym).schema
                      s[:property_list] = s['properties'].keys
                      [schema, s] } ]
    json_response( schemas )
  end

  Endpoint.get('/pas/schemas/:schema')
    .description("Get an ArchivesSpace schema")
    .params(["schema", String, "Schema name to retrieve"])
    .permissions([])
    .returns([200, "ArchivesSpace (:schema)"],
             [404, "Schema not found"]) \
  do
    schema = params[:schema]
    if models.has_key? schema
      sch = JSONModel(schema.to_sym).schema
      sch[:property_list] = sch['properties'].keys
      json_response( sch )
    else
      raise NotFoundException.new
    end
  end

  Endpoint.get('/repositories/:repo_id/archival_objects/:id/tree/node')
    .description("Fetch tree information for the Archival Object record within a tree")
    .params(["id", :id],
            ["repo_id", :repo_id],
            ["published_only", BooleanParam, "Whether to restrict to published/unsuppressed items", :default => false])
    .permissions([:view_repository])
    .returns([200, TreeDocs::NODE_DOCS]) \
  do
    ao = ArchivalObject.get_or_die(params[:id])
    res = Resource.get_or_die(ao.root_record_id)
    large_tree = LargeTree.new(res, {:published_only => params[:published_only]})
    large_tree.add_decorator(LargeTreeResource.new)

    json_response(large_tree.node(ao))
  end
end
