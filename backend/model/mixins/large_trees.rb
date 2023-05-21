module LargeTrees
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        if obj.methods.include?(:root_record_id)
          json['tree'] = {'ref' => obj.uri + '/tree/node'}
        else
          json['tree'] = {'ref' => obj.uri + '/tree/root'}
        end
      end

      jsons
    end
  end
end
