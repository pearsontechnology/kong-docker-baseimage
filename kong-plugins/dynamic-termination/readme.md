# Kong Dynamic Termination Plugin

This plugin allows you to terminate an incoming request with a custom status code, headers, and body.  Allowing you to do things like dynamic redirects based on URI parameters, serving "static" content, etc...

While it could be used to completely provide a Lua based website from Kong, it shouldn't be used for this.
