###*
# Module dependencies.
###

_ = require 'lodash'
path = require 'path'
lusca = require 'lusca'
flash = require 'express-flash'
logger = require 'morgan'
multer = require 'multer'
express = require 'express'
favicon = require 'serve-favicon'
Sockets = require './lib/sockets'
session = require 'express-session'
mongoose = require 'mongoose'
passport = require 'passport'
compress = require 'compression'
bodyParser = require 'body-parser'
MongoStore = require('connect-mongo')(session)
errorHandler = require 'errorhandler'
cookieParser = require 'cookie-parser'
connectAssets = require 'connect-assets'
{EventEmitter} = require 'events'
methodOverride = require 'method-override'
UserController = require './controllers/user'
TopologyManager = require './lib/topology_manager'
expressValidator = require 'express-validator'

###*
# Central Data Event Emitter
###

emitter = new EventEmitter
manager = new TopologyManager

###*
# Controllers (route handlers).
###

apiController = require './controllers/api'
homeController = require './controllers/home'

userController = new UserController
SummaryController = require './controllers/summary'
summaryController = new SummaryController
DataTypeController = require './controllers/datatype'
dataTypeController = new DataTypeController
StreamController = require './controllers/stream'
streamController = new StreamController emitter
contactController = require './controllers/contact'
TopologyController = require './controllers/topology'
topologyController = new TopologyController manager

###*
# API keys and Passport configuration.
###

secrets = require './config/secrets'
passportConf = require './config/passport'

###*
# Create Express server.
###

app = express()

###*
# Connect to MongoDB.
###

mongoose.connect secrets.db
mongoose.connection.on 'error', ->
  console.error 'MongoDB Connection Error. Please make sure that MongoDB is running.'
  return

###*
# Express configuration.
###

allowCrossDomain = (req, res, next) ->
  res.header 'Access-Control-Allow-Origin', 'example.com'
  res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
  res.header 'Access-Control-Allow-Headers', 'Content-Type'
  next()
  return

app.set 'view engine', 'jade'
app.set 'views', "#{__dirname}/public/html/views"
app.set 'port', process.env.PORT or 9821
app.use express.static(__dirname + '/node_modules')
app.use '/build', express.static('build')
app.use '/node_modules', express.static('node_modules')
app.use '/package.json', express.static('package.json')
app.use compress()
app.use connectAssets
  paths: [
    path.join(__dirname, 'public/css')
    path.join(__dirname, 'public/js')
    path.join(__dirname, 'public/img')
  ]

app.use logger('dev')
app.use favicon(path.join(__dirname, 'public/favicon.png'))
app.use bodyParser.json()
app.use bodyParser.raw()
app.use bodyParser.text()
app.use bodyParser.urlencoded(extended: true)
app.use multer(dest: path.join(__dirname, 'uploads'))
app.use expressValidator()
app.use methodOverride()
app.use cookieParser()

masterSession = session
  resave: true
  saveUninitialized: true
  secret: secrets.sessionSecret
  store: new MongoStore
    url: secrets.db
    autoReconnect: true

app.use masterSession
app.use passport.initialize()
app.use passport.session()
app.use flash()
app.use (req, res, next) ->
  res.locals.user = req.user
  next()

app.use (req, res, next) ->
  if /api/i.test(req.path)
    req.session.returnTo = req.path
  next()

app.use express.static(path.join(__dirname, 'public'), maxAge: 31557600000)

###*
# Primary app routes.
###

app.get '/', (req, res) ->
  res.sendFile __dirname + '/index.html'
app.get '/index.html', (req, res) ->
  res.sendFile __dirname + '/index.html'

app.get '/user', passportConf.isAuthenticated, userController.getUser
app.post '/login', userController.postLogin
app.get '/logout', userController.logout
app.get '/forgot', userController.getForgot
app.post '/forgot', userController.postForgot
app.get '/reset/:token', userController.getReset
app.post '/reset/:token', userController.postReset
app.get '/signup', userController.getSignup
app.post '/signup', userController.postSignup
app.get '/account', passportConf.isAuthenticated, userController.getAccount
app.post '/account/profile', passportConf.isAuthenticated, userController.postUpdateProfile
app.post '/account/password', passportConf.isAuthenticated, userController.postUpdatePassword
app.post '/account/delete', passportConf.isAuthenticated, userController.postDeleteAccount
app.get '/account/unlink/:provider', passportConf.isAuthenticated, userController.getOauthUnlink

###*
# DataFountain routes
###

app.get '/api/users', userController.getAll
app.get '/api/summary', summaryController.summary
app.get '/api/:user/streams/:streamId', userController.getStream
app.get '/api/:user/streams', userController.getStreams
app.get '/api/:user/datatypes', userController.getDataTypes
app.post '/api/datatype', dataTypeController.create
app.post '/api/stream', streamController.create
app.delete '/api/stream', streamController.delete
app.post '/api/:user/streams/:streamId', ->
  streamController.push.apply streamController, arguments

googleAuth = passport.authenticate 'google',
  failureRedirect: '/#login'
  accessType: 'offline'
  scope: [
    'profile email'
  ]

app.get '/auth/google', googleAuth
app.get '/auth/google/callback', googleAuth, (req, res) ->
  console.log "GOOGLE AUTH CALLBACK", req.session.returnTo
  res.redirect req.session.returnTo || '/'

###*
# Error Handler.
###

app.use errorHandler()

###*
# Start Express server.
###

server = app.listen app.get('port'), ->
  console.log 'Express server listening on port %d in %s mode', app.get('port'), app.get('env')

sockets = new Sockets server, app, masterSession
sockets.setup()

manager.setSockets sockets

module.exports = app