class JSONModelType

  def self.stub(opts = {})
    expand = opts.fetch(:expand) { [] }
    stub = {}
    props = schema['properties']
    props.each_pair do |k,v|
      if k != 'jsonmodel_type' && (v['ifmissing'] == 'error' || expand.include?(k))
        if v['type'] == 'array'
          stub[k] = [ type_of("#{k}/items").stub(:expand => expand) ]
        elsif v['type'] == 'object'
          stub[k] = type_of("#{k}/properties/ref").stub(:expand => expand)
        else
          typ = v['type']
          if typ.to_s.start_with?('JSONModel')
            stub[k] = type_of(k).schema['uri'] + '/[ID]'
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
