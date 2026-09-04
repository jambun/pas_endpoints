{
  "tree" => {
    "type" => "object",
    "readonly" => "true",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
#        "type" => "JSONModel(:resource_tree) uri",
        "type" => "string",
        "ifmissing" => "error"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
