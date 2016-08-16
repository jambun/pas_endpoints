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
                      e[:uri] == params[:uri] && (params.has_key?(:method) ? e[:method] == params[:method].intern : true)
                    })
    else
      json_response(ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}.map{ |e| e[:uri] })
    end
  end


  Endpoint.get('/stub/:model')
    .description("Get a stub record for a JSONModel")
    .params(["model", String, "JSONModel to stub"])
    .permissions([])
    .returns([200, "JSONModel(model)"],
             [404, "Model not found"]) \
  do
    model = params[:model]
    if models.has_key? model
      json_response( JSONModel(model.to_sym).stub )
    else
      raise NotFoundException.new
    end
  end

end
