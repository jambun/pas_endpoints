class JSONModelType

  def self.stub
    stub = {}
    props = schema['properties']
    props.each_pair do |k,v|
      if k != 'jsonmodel_type' && v['ifmissing'] == 'error'
        if v['type'] == 'array'
          stub[k] = [ type_of("#{k}/items").stub ]
        elsif v['type'] == 'object'
          stub[k] = type_of("#{k}/properties/ref").stub
        else
          typ = type_of(k)
          if typ.to_s.start_with?('JSONModel')
            stub[k] = typ.schema['uri'] + '/[ID]'
          else
            if v.has_key?('dynamic_enum')
              values = Enumeration.filter(:name => v['dynamic_enum']).first.enumeration_value.map {|v| v[:value]}.join('|')
              stub[k] = '(' + values + ')'
            else
              stub[k] = '(' + type_of(k).to_s + ')'
            end
          end
        end
      end
    end
    stub
  end

end
