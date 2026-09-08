{
  "tree" => {
    "type" => "object",
    "readonly" => "true",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => "string",
#        "type" => "JSONModel(:resource_tree) uri",
        "ifmissing" => "error"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
