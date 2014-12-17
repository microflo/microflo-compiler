express = require 'express'
busboy = require 'connect-busboy'
chance = require 'chance'

child_process = require 'child_process'
fs = require 'fs'
path = require 'path'

class CompileJob
    constructor: (workdir) ->
        @workdir = workdir
        @files = {}
        @fields = {}
        @status = 'new'
        @options =
            verbose: true

        @stdout = ""
        @stderr = ""
        @progress = 0
        @process = null

    build: () ->
        if @status != 'new'
            return

        makeFile = './node_modules/microflo/Makefile'
        target = 'build-arduino'
        cmd = 'make'
        args = [ '-f', makeFile, target, "BUILD_DIR=#{@workdir}"]
        options =
            cwd: './'
            timeout: 60*10e3

        console.log cmd, args.join ' ' if @options.verbose
        @process = child_process.spawn cmd, args
        @process.stdout.on 'data', (data) =>
            @stdout += data.toString()
        @process.stderr.on 'data', (data) =>
            @stderr += data.toString()
        @process.on 'error', =>
           @status = 'spawn-error'
        @process.on 'close', =>
            console.log 'close', @stderr, @stdout if @options.verbose
            @status = 'unknown'

    receiveFile: (fieldname, file, filename) ->
        @files[filename] = filename
        p = path.join @workdir, filename
        stream = fs.createWriteStream p
        file.pipe stream

    receiveField: (fieldname, value) ->
        @fields[fieldname] = value

    getState: () ->
        s =
            status: @status
            files: @files
            attributes: @fields
            progress: @progress
            stdout: @stdout
            stderr: @stderr
        return s

getApp = () ->
    app = express()
    app.use busboy()

    app.workdir = './tempp'
    app.jobs = {} # TODO: use database, or re-populate from disk on startup

    app.post '/job', (req, res) ->
        jobId = (new chance()).guid()
        job = new CompileJob path.join app.workdir, jobId
        app.jobs[jobId] = job

        req.pipe(req.busboy)
        req.busboy.on 'file', (fieldname, file, filename) ->
            job.receiveFile fieldname, file, filename
        req.busboy.on 'field', (key, value) ->
            job.receiveField key, value
        req.on 'end', ->
            job.build() # Fire away, app should poll later to
            res.status 201
            res.location "/job/#{jobId}"
            res.end()

    # TODO: disable for production, so people cannot sniff other peoples jobs
    app.get '/job', (req, res) ->
        jobs = Object.keys app.jobs
        res.json { jobs: jobs }

    app.get '/job/:id', (req, res) ->
        job = app.jobs[req.params.id]
        if not job?
            res.status 404
            return res.end()
        res.json job.getState()
        

    return app

main = () ->
    app = getApp()
    app.listen 8080

exports.main = main
exports.getApp = getApp
