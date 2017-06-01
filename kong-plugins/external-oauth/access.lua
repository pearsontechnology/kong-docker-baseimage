
-- Copyright 2016 Niko Usai

--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at

--        http://www.apache.org/licenses/LICENSE-2.0

--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
-- limitations under the License.

local _M = {}
local cjson = require "cjson.safe"
local pl_stringx = require "pl.stringx"
local http = require "resty.http"
local crypto = require "crypto"

local OAUTH_CALLBACK = "^%s/oauth2/callback(/?(\\?[^\\s]*)*)$"

function _M.run(conf)
     -- Check if the API has a request_path and if it's being invoked with the path resolver
    local path_prefix = (ngx.ctx.api.request_path and pl_stringx.startswith(ngx.var.request_uri, ngx.ctx.api.request_path)) and ngx.ctx.api.request_path or ""
    if pl_stringx.endswith(path_prefix, "/") then
        path_prefix = path_prefix:sub(1, path_prefix:len() - 1)
    end

    local callback_url = ngx.var.scheme .. "://" .. ngx.var.host .. path_prefix .. "/oauth2/callback"

    -- check if we're calling the callback endpoint
    if ngx.re.match(ngx.var.request_uri, string.format(OAUTH_CALLBACK, path_prefix)) then
        handle_callback(conf, callback_url)
    else 
        local encrypted_token = ngx.var.cookie_EOAuthToken 
        -- check if we are authenticated already
        if encrypted_token then
            ngx.header["Set-Cookie"] = "EOAuthToken="..encrypted_token.."; path=/;Max-Age=3000;HttpOnly"
            
            local access_token = decode_token(encrypted_token, conf)
            if not access_token then
                -- broken access token
                return redirect_to_auth( conf, callback_url )
            end

            -- Get user info
            -- TODO: don't know if makes sense to do everytime this call to check the validity of the token 
            --  or cache the result in a Cookie that expires early
            local httpc = http:new()
            local res, err = httpc:request_uri(conf.user_url, {
                method = "GET",
                ssl_verify = false,
                headers = {
                  ["Authorization"] = "Bearer ".. access_token,
                }
            })

            if res then
                -- redirect to auth if user result is invalid not 200
                if res.status ~= 200 then
                    return redirect_to_auth( conf, callback_url )
                end

                local json = cjson.decode(res.body)
                ngx.log(ngx.NOTICE, res.body)

                for i, key in ipairs(conf.user_keys) do
                    ngx.header["X-Oauth-"..key] = json[key]
                end
                ngx.header["X-Oauth-Token"] = access_token
            else
                return redirect_to_auth( conf, callback_url )
            end

        else
            return redirect_to_auth( conf, callback_url )
        end
    end
    
end

function redirect_to_auth( conf, callback_url )
    -- Track the endpoint they wanted access to so we can transparently redirect them back
    ngx.header["Set-Cookie"] = "EOAuthRedirectBack="..ngx.var.request_uri.."; path=/;Max-Age=120"
    -- Redirect to the /oauth endpoint
    local oauth_authorize = conf.authorize_url .. "?response_type=code&client_id=" .. conf.client_id .. "&redirect_uri=" .. callback_url .. "&scope="..conf.scope
    return ngx.redirect(oauth_authorize)
end

function encode_token(token, conf)
    return ngx.encode_base64(crypto.encrypt("aes-128-cbc", token, crypto.digest('md5',conf.client_secret)))
end

function decode_token(token, conf)
    status, token = pcall(function () return crypto.decrypt("aes-128-cbc", ngx.decode_base64(token), crypto.digest('md5',conf.client_secret)) end)
    if status then 
        return token
    else
        return nil
    end 
end

-- Callback Handling
function  handle_callback( conf, callback_url )
    local args = ngx.req.get_uri_args()
    
    if args.code then
        local httpc = http:new()
        local res, err = httpc:request_uri(conf.token_url, {
            method = "POST",
            ssl_verify = false,
            body = "grant_type=authorization_code&client_id="..conf.client_id.."&client_secret="..conf.client_secret.."&code="..args.code.."&redirect_uri=".. callback_url,
            headers = {
              ["Content-Type"] = "application/x-www-form-urlencoded",
            }
        })

        if not res then
            ngx.status = res.status
            ngx.say("failed to request: ", err)
            ngx.exit(ngx.HTTP_OK)
        end

        local json = cjson.decode(res.body)
        local access_token = json.access_token
        if not access_token then
            ngx.status = 500
            ngx.say(json.error_description)
            ngx.exit(ngx.HTTP_OK)
        end

        
        ngx.header["Set-Cookie"] = "EOAuthToken="..encode_token( access_token, conf ).."; path=/;Max-Age=3000;HttpOnly"
        -- Support redirection back to your request if necessary
        local redirect_back = ngx.var.cookie_EOAuthRedirectBack
        if redirect_back then
            return ngx.redirect(redirect_back)
        else
            return ngx.redirect(ngx.ctx.api.request_path)
        end
    else 
        ngx.status = ngx.HTTP_BAD_REQUEST
        ngx.say("Nope")
        ngx.exit(ngx.HTTP_OK)
    end
end

return _M