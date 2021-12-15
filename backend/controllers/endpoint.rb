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


  Endpoint.get('/enumerations')
    .description("List enumerations without nested enumeration_values")
    .params()
    .permissions([])
    .returns([200, "[(:enumeration)]"]) \
  do
    enums = Enumeration.sequel_to_jsonmodel(Enumeration.all)
    enums.map{|e| eh = e.to_hash; eh.delete('enumeration_values'); eh}
    json_response(enums)
  end

end
