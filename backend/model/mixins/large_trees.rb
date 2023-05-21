module LargeTrees
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.zip(objs).each do |json, obj|
        json['tree'] = {'ref' => obj.uri + '/tree/root'}
      end

      jsons
    end
  end
end
