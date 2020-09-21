class JSONModelType

  STUB_SKIP_FIELDS = [
                      'jsonmodel_type',
                      'lock_version',
                     ]

  def self.type_of(path)
    types = Array((JSONSchemaUtils.schema_path_lookup(self.schema, path) || {})["type"])
    models = types.map do |type|
      ref = JSONModel.parse_jsonmodel_ref(type.is_a?(Hash) ? type['type'] : type)
      if ref
        JSONModel.JSONModel(ref.first)
      else
        Kernel.const_get(type.capitalize)
      end
    end

    models.length > 1 ? models : models.first
  end


  def self.complete_uri(uri, opts)
    uri.sub!(':repo_id', opts[:repo_id].to_s) if opts[:repo_id]
    uri + '/:id'
  end


  def self.stub(opts = {})
    expand = opts.fetch(:expand, [])
    stub = {}
    props = schema['properties']
    props.each_pair do |k,v|
      if !STUB_SKIP_FIELDS.include?(k) &&
          !(v.has_key?('readonly') && v['readonly']) &&
          (v['ifmissing'] == 'error' || expand.include?('ALL') || expand.include?(k))
        if v['type'] == 'array'
          if v['items']['subtype'] == 'ref'
            stub[k] = Array(v['items']['properties']['ref']['type']).map{|t|
              ref = JSONModel.parse_jsonmodel_ref(t.is_a?(Hash) ? t['type'] : t)
              {'ref' => complete_uri(JSONModel.JSONModel(ref.first).schema['uri'], opts)}
             }
          else
            stub[k] = Array(type_of("#{k}/items")).map{|m|
              m.respond_to?(:stub) ? m.stub(opts) : m
            }
          end
        elsif v['type'].end_with?(') object')
          stub[k] = type_of(k).stub(opts)
        elsif v['type'] == 'object'
          typ = type_of("#{k}/properties/ref")
          stub[k] = typ.stub(opts) if typ && typ.respond_to?(:stub)
        else
          typ = v['type']
          if typ.to_s.start_with?('JSONModel')
            stub[k] = complete_uri(type_of(k).schema['uri'], opts)
          else
            if v.has_key?('dynamic_enum')
              values = Enumeration.filter(:name => v['dynamic_enum']).first.enumeration_value.map {|v| v[:value]}.join('|')
              stub[k] = '(' + values + ')'
            else
              stub[k] = '(' + typ.to_s + ')'
            end
          end
        end
      end
    end
    stub
  end

end
