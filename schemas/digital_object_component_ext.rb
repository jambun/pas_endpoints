{
  "tree" => {
    "type" => "object",
    "readonly" => "true",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
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
