return {
  no_consumer = true,
  fields = {
    script = { type = "string", default = [=[return {
  username = "anonymous",
  password = "password"
}]=], multiline = true, required = true }
  }
}
