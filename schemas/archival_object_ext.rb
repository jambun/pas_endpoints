{
  "tree" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => "JSONModel(:resource_tree) uri",
        "ifmissing" => "error"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
