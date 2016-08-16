class Stub

  def initialize(model)
    @schema = JSONModel(model.to_sym).schema
  end


  def stub
    'STUB'
  end

end
