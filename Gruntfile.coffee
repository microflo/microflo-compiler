module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'
          require: 'coffee-script/register'

    # Web server for the browser tests
    connect:
      server:
        options:
          port: 8000

    # BDD tests on browser
    mocha_phantomjs:
      all:
        options:
          output: 'test/result.xml'
          reporter: 'spec'
          urls: ['http://localhost:8000/test/runner.html']

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-clean'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-mocha-phantomjs'

  @loadNpmTasks 'grunt-exec'

  # Our local tasks
  @registerTask 'build', 'Build MicroFlo for the chosen target platform', (target = 'all') =>
    # @task.run 'coffee'

  @registerTask 'test', 'Build MicroFlo and run automated tests', (target = 'all') =>
    @task.run 'build'
    if target is 'all' or target is 'nodejs'
      @task.run 'mochaTest'
#    if target is 'all' or target is 'browser'
      #@task.run 'connect'
      #@task.run 'mocha_phantomjs'

  @registerTask 'default', ['test']

