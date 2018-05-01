local cjson = require "cjson"
local url = require "socket.url"

local string_find = string.find

function table.clone (t) -- deep-copy a table
  if type(t) ~= "table" then
    return t
  end
  local meta = getmetatable(t)
  local target = {}
  for k, v in pairs(t) do
    target[k] = type(v) == "table" and table.clone(v) or v
  end
  setmetatable(target, meta)
  return target
end

function table.extend (src, ext) -- deep-copy a table
  local h = table.clone(src)
  for k, v in pairs(ext) do
    h[k]=v
  end
  return h
end

function table.filter (t, iter)
  local out = {}
  local nk=1

  for k, v in pairs(t) do
    if iter(v, k, t) then
      out[nk] = v
      nk = nk + 1
    end
  end

  return out
end

function table.map (t, iter)
  local out = {}

  for k, v in pairs(t) do
    out[k] = iter(v, k, t)
  end

  return out
end

--[[
ngx.STDERR
ngx.EMERG
ngx.ALERT
ngx.CRIT
ngx.ERR
ngx.WARN
ngx.NOTICE
ngx.INFO
ngx.DEBUG
]]

local function log_write(level, ...)
end

local function log_error(...)
  ngx.log(ngx.ERR, ...)
end

local function log_warn(...)
  ngx.log(ngx.WARN, ...)
end

local function log_info(...)
  ngx.log(ngx.INFO, ...)
end

local function log_debug(...)
  ngx.log(ngx.DEBUG, ...)
end

local log = {
  write = log_write,
  error = log_error,
  warn  = log_warn,
  info  = log_info,
  debug = log_debug,
}

local function dump(t, indent)
  if indent == nil then
    indent = ''
  end
  if type(t)=="table" then
    local s = '{\n'
    for k, v in pairs(t) do
      s = s..indent..'  '..k..": "..dump(v, indent.."  "):gsub("^%s*(.-)%s*$", "%1").."\n"
    end
    return s..indent..'}\n'
  end
  return indent..tostring(t)
end

local function decode_args(body)
  if body then
    return ngx_decode_args(body)
  end
  return {}
end

local function get_content_type(content_type)
  if content_type == nil then
    return
  end
  local contentType = content_type:lower()
  if string_find(contentType, "text/html", nil, true) then
    return 'html'
  end
  if string_find(contentType, "text/plain", nil, true) then
    return 'text'
  end
  if string_find(contentType, "application/json", nil, true) then
    return 'json'
  end
  if string_find(contentType, "multipart/form-data", nil, true) then
    return 'multi-part'
  end
  if string_find(contentType, "application/x-www-form-urlencoded", nil, true) then
    return 'form-encoded'
  end
  return 'unknown'
end

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

local function mapTo(scope, map)
  local mtype = type(map)
  if mtype == "table" then
    local res = {}
    for k, v in pairs(map) do
      res[k] = mapTo(scope, v)
    end
    return res
  end
  if mtype == "function" then
    return map(src)
  end
  if mtype == "string" then
    local f, m = (string.find(map, 'return ') ~= nil) and loadstring("return function(src)\n  "..map.."\nend") or loadstring("return function(src)\n  return "..map.."\nend")
    if not f then
      log.error('ERROR in ', map, ' - ', f, m)
      return nil, m
    end
    local env = getfenv(2)
    env.log = log
    env.dump = dump
    for k, v in pairs(scope) do
      env[k] = v
    end
    setfenv(f, env)
    local ok, worker, err = pcall(f)
    if err then
      log_error('ERROR with map function ', err, ' in ', map)
      return err
    end
    return mapTo(src, worker)
  end
end

local function isempty(s)
  return s == nil or s == ''
end

local function keys(t)
  local keyset={}
  local n=0
  for k, v in pairs(t) do
    n=n+1
    keyset[n]=k
  end
  return keyset
end
