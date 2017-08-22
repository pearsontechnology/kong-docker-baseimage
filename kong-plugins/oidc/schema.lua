return {
  no_consumer = true,
  fields = {
-- lua-resty-openidc Attributes
    client_id                  = { type = "string", required = true},
    client_secret              = { type = "string", required = true},
    discovery                  = { type = "string", required = true, default = "https://.well-known/openid-configuration"},
    redirect_uri_path          = { type = "string"},
    scope                      = { type = "string", required = true, default = "openid"},
    response_type              = { type = "string", required = true, default = "code"},
    ssl_verify                 = { type = "string", required = true, default = "no"},
    token_endpoint_auth_method = { type = "string", required = true, default = "client_secret_post", enum={"client_secret_basic", "client_secret_post"}},

    --authorization_params = { hd="pingidentity.com" },
    --refresh_session_interval = 900,
    --iat_slack = 600,
    --redirect_uri_scheme = "https",
    --logout_path = "/logout",
    --redirect_after_logout_uri = "/",
    --redirect_after_logout_with_id_token_hint = true,
    --access_token_expires_in = 3600
    --access_token_expires_leeway = 0
    --force_reauthorize = false

-- Custom Attributes
    --session_secret             = { type = "string", required = false},
    recovery_page_path         = { type = "string"}
  }
}
