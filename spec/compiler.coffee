
compiler = require '../lib/compiler'

http = require 'http'
chai = require 'chai'
needle = require 'needle'

currentTime = () ->
  return (new Date()).getTime()

pollJobUntil = (url, predicate, callback) ->
  deadline = new Date currentTime()+8000
  interval = null

  done = () ->
    clearInterval interval
    callback.apply this, arguments
  attempt = () ->
    needle.get url, (err, res, body) ->
      return done err if err
      return done null if predicate body
      return done (new Error 'Timeout') if currentTime() > deadline.getTime()

  interval = setInterval attempt, 500

describe 'Compiler API', ->
  port = 3333
  base = "http://localhost:#{port}"
  server = null

  before (done) ->
    app = compiler.getApp()
    server = app.listen port, ->
      done()
  after (done) ->
    server.close()
    done()

  describe 'Job', ->
    location = null
    describe 'creating with minimal info', ->
      it 'should result in 201 CREATED', (done) ->
        data =
          target: "arduino-nano328"
        options =
          multipart: true
        needle.post base+'/job', data, options, (err, res, body) ->
          chai.expect(err).to.equal null
          chai.expect(res.statusCode).to.equal 201
          chai.expect(res.headers.location).to.have.string '/job/'
          done()

    describe 'polling job status', ->
      it 'should return current state', (done) ->
        @timeout 10000
        data =
          target: "arduino-nano328"
        options =
          multipart: true
        job = null
        needle.post base+'/job', data, options, (err, res, body) ->
          chai.expect(err).to.equal null
          job = res.headers.location
          notNew = (body) ->
            console.log body.status
            return body.status != 'new'
          pollJobUntil base+job, notNew, (err) ->
            chai.expect(err).to.equal null
            done()

