Resource.include(LargeTrees)
ArchivalObject.include(LargeTrees)
DigitalObject.include(LargeTrees)
Classifications.include(LargeTrees)

class JSONModelType

  STUB_SKIP_FIELDS = [
                      'lock_version',
                     ]

  # non-schema validations are a bane
  STUB_DEFAULT_EXPANSIONS = {
    :lang_material => ['language_and_script'],
    :date => ['begin'],
    :location => ['barcode'],
  }


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
    expand = (opts.fetch(:expand, []) + STUB_DEFAULT_EXPANSIONS.fetch(self.record_type.intern, [])).uniq
    stub = {}
    passed_props = opts.delete(:properties)
    props = passed_props || schema['properties']
    props.each_pair do |k,v|
      if !STUB_SKIP_FIELDS.include?(k) &&
          !(v.has_key?('readonly') && v['readonly']) &&
          (v['ifmissing'] == 'error' || expand.include?('ALL') || expand.include?(k))

        v['type'] = v['type'].first['type'] if v['type'].is_a?(Array)

        if k == 'jsonmodel_type'
          stub[k] = self.record_type
        elsif k == 'ref'
          t = v['type']
          stub[k] = complete_uri(JSONModel.JSONModel(JSONModel.parse_jsonmodel_ref(t.is_a?(Hash) ? t['type'] : t).first).schema['uri'], opts)
        elsif v['type'] == 'array'
          if v['items']['subtype'] == 'ref'
            stub[k] = [ self.stub(opts.merge(:properties => v['items']['properties'])) ]
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
              values = Enumeration.filter(:name => v['dynamic_enum']).first.enumeration_value.map {|v| v[:value]}
              if values.length > 1
                stub[k] = '(' + values.join('|') + ')'
              else
                stub[k] = values.first
              end
            elsif self.record_type == 'date' && (k == 'begin' || k == 'end')
              stub[k] = '(date)'
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

class DB
  class DBPool
    unless AppConfig.has_key?(:pas_instance_label) && self.method_defined?(:sysinfo_pre_pas_endpoints)
      alias_method(:sysinfo_pre_pas_endpoints, :sysinfo)
      def sysinfo
        info = sysinfo_pre_pas_endpoints
        info['label'] = AppConfig[:pas_instance_label]
        info
      end
    end
  end
end

module JSONSchemaUtils
  self.singleton_class.send(:alias_method, :parse_schema_messages_pre_pas_endpoints, :parse_schema_messages)
  def self.parse_schema_messages(messages, validator)
    msgs = parse_schema_messages_pre_pas_endpoints(messages, validator)
    if coded = msgs.dig(:errors, 'coded_errors')
      msgs[:errors]['decoded_errors'] = coded.map{|err| err + ': ' + I18n.t('validation_errors.' + err) }
    end
    msgs
  end
end
