local Errors = require "kong.dao.errors"

return {
  self_check = validate_routes,
  fields = {
    script = { type = "string", default = [=[return {
  content_type = "text/html; charset=utf-8",
  status_code = 200,
  headers = {},
  body = [[<html>
  <head>
    <title>Hi</title>
  </head>
  <body>
    <h1>Hello World!</h1>
  </body>
</html>]]
}]=], multiline = true, required = true }
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    if plugin_t.status_code then
      if plugin_t.status_code < 100 or plugin_t.status_code > 599 then
        return false, Errors.schema("status_code must be between 100 .. 599")
      end
    end

    if not plugin_t.script then
      return false, Errors.schema("script can not be empty")
    end

    return true
  end
}
