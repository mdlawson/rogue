express = require "express"
app = express()
path = require "path"

app.get "/", (req,res) -> res.sendfile __dirname + "/index.html"

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.static path.normalize(__dirname + "/../lib")
  app.use express.static __dirname
  app.use app.router

app.listen 8000

console.log "test server listening on 8000"
module.exports = app