express = require "express"
app = express()
path = require "path"

app.get "/", (req,res) -> res.sendfile __dirname + "/rogue.html"

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.static __dirname
  app.use app.router

app.listen 8080

console.log "docs server listening on 8080"
module.exports = app