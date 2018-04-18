local responses = require "kong.tools.responses"
local cjson = require "cjson"
local url = require "socket.url"
local meta = require "kong.meta"
local BasePlugin = require "kong.plugins.base_plugin"

local helpers = require "kong.plugins.rewrite.helpers"

local string_find = string.find

local mapTo = helpers.mapTo
local isempty = helpers.isempty
local dump = helpers.dump
local log = helpers.log
local get_content_type = helpers.get_content_type

local server_header = meta._NAME.."/"..meta._VERSION

local ngx_decode_args = ngx.decode_args
local req_read_body = ngx.req.read_body
local req_get_method = ngx.req.get_method
local req_get_body_data = ngx.req.get_body_data
local req_get_headers = ngx.req.get_headers
local req_get_uri_args = ngx.req.get_uri_args

local function get_response(config, scope)
  return mapTo(scope, config.script)
end

local function decode_body(content_type, body, content_type_value)
  local is_body_transformed = false
  local content_length = (body and #body) or 0

  if not content_type then
    return ''
  elseif content_type == 'form-encoded' then
    return decode_args(body)
  elseif content_type == 'multi-part' then
    return multipart(body and body or "", content_type_value)
  elseif content_type == 'text' then
    return body
  elseif content_type == 'html' then
    return body
  elseif content_type == 'json' then
    local json, err = cjson.decode(body)
    if err then
      return body
    end
    return json
  end
  return body
end

local function get_req(get_body)
  if get_body then
    req_read_body()
  end
  local body = (get_body) and req_get_body_data() or ''
  local method = (req_get_method() or "GET"):upper()
  local headers = req_get_headers()
  local content_type_value = headers['content-type']
  local content_type = get_content_type(content_type_value)
  local query = req_get_uri_args()
  local payload = decode_body(content_type, body, content_type_value)
  local path = ngx.var.request_uri
  return {
    content_type_value = content_type_value,
    content_type = content_type,
    method = method,
    path = path,
    headers = headers,
    body = body,
    payload = payload,
    query = query,
  }
end

local function get_scope(conf, options)
  local scope = ngx.ctx.scope or {}
  scope.req = scope.req or get_req(options.access)
  return scope
end

function get_res_content_type(response)
  if response.content_type then
    return response.content_type
  end
  if type(response.headers) == "table" then
    if response.headers["Content-Type"] then
      return response.headers["Content-Type"]
    end
    if response.headers["content-type"] then
      return response.headers["content-type"]
    end
  end
  return "text/html; charset=utf-8"
end

local TerminationHandler = BasePlugin:extend()
TerminationHandler.PRIORITY = 2
TerminationHandler.VERSION = "0.0.1"

function TerminationHandler:new()
  TerminationHandler.super.new(self, "dynamic-termination")
end

function TerminationHandler:access(conf)
  TerminationHandler.super.access(self)

  ngx.ctx.scope = {}
  local scope = get_scope(conf, {access = true})
  local requestedRoute = scope.req.path

  local response = get_response(conf, scope)

  if not response then
    return
  end

  local response_status_code = response.status_code
  local response_content_type = get_res_content_type(response)
  local response_response = response.body

  if not response_status_code then
    response_status_code = 200
  end

  if type(response.headers) == "table" then
    for name, value in pairs(response.headers) do
      ngx.header[name] = value
    end
  end

  if string_find(response_content_type, "json", nil, true) then
    return responses.send(response_status_code, response_response)
  end

  ngx.status = response_status_code

  ngx.header["Content-Type"] = response_content_type
  ngx.header["Server"] = server_header

  ngx.say(response_response)
  return ngx.exit(response_status_code)
end

return TerminationHandler
