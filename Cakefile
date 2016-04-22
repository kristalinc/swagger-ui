fs          = require 'fs'
path        = require 'path'
{exec}      = require 'child_process'
less        = require 'less'

sourceFiles  = [
  'SwaggerUiRouter'
  'model/Choices'
  'model/Expansions'
  'model/Filters'
  'model/Param'
  'model/Signature'
  'model/Operation'
  'model/Resource'
  'model/Api'
  'model/Type'
  'view/MainView'
  'view/ResourceView'
  'view/OperationView'
  'view/StatusCodeView'
  'view/ParameterView'
  'view/SignatureView'
  'view/ContentTypeView'
  'view/ResponseContentTypeView'
  'view/ParameterContentTypeView'
  'view/ParameterChoiceView'
  'view/NavView'
  'view/TypeView'
  'view/GlobalParametersView'
]


task 'clean', 'Removes distribution', ->
  console.log 'Clearing dist...'
  exec 'rm -rf dist'

task 'dist', 'Build a distribution', ->
  console.log "Build distribution in ./dist"
  fs.mkdirSync('dist') if not fs.existsSync('dist')
  fs.mkdirSync('dist/lib') if not fs.existsSync('dist/lib')

  appContents = new Array remaining = sourceFiles.length
  for file, index in sourceFiles then do (file, index) ->
    console.log "   : Reading src/main/coffeescript/#{file}.coffee"
    fs.readFile "src/main/coffeescript/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      precompileTemplates() if --remaining is 0

  precompileTemplates= ->
    console.log '   : Precompiling templates...'
    templateFiles  = fs.readdirSync('src/main/template')
    templateContents = new Array remaining = templateFiles.length
    for file, index in templateFiles then do (file, index) ->
      console.log "   : Compiling src/main/template/#{file}"
      exec "handlebars src/main/template/#{file} -f dist/_#{file}.js", (err, stdout, stderr) ->
        throw err if err
        fs.readFile 'dist/_' + file + '.js', 'utf8', (err, fileContents) ->
          throw err if err
          templateContents[index] = fileContents
          fs.unlink 'dist/_' + file + '.js'
          if --remaining is 0
            templateContents.push '\n\n'
            fs.writeFile 'dist/_swagger-ui-templates.js', templateContents.join('\n\n'), 'utf8', (err) ->
              throw err if err
              build()


  build = ->
    lessc()
    console.log '   : Collecting Coffeescript source...'

    appContents.push '\n\n'
    fs.writeFile 'dist/_swagger-ui.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      console.log '   : Compiling...'
      exec 'coffee --compile dist/_swagger-ui.coffee', (err, stdout, stderr) ->
        throw err if err
        fs.unlink 'dist/_swagger-ui.coffee'
        console.log '   : Combining with javascript...'

        fs.readFile 'package.json', 'utf8', (err, fileContents) ->
          obj = JSON.parse(fileContents)
          exec 'echo "// swagger-ui.js" > dist/swagger-ui.js'
          exec 'echo "// version ' + obj.version + '" >> dist/swagger-ui.js'
          exec 'cat node_modules/bootstrap/js/scrollspy.js node_modules/bootstrap/js/affix.js dist/_swagger-ui-templates.js dist/_swagger-ui.js >> dist/swagger-ui.js', (err, stdout, stderr) ->
            throw err if err
            fs.unlink 'dist/_swagger-ui.js'
            fs.unlink 'dist/_swagger-ui-templates.js'
            console.log '   : Minifying all...'
            exec 'java -jar "./bin/yuicompressor-2.4.7.jar" --type js -o ' + 'dist/swagger-ui.min.js ' + 'dist/swagger-ui.js', (err, stdout, stderr) ->
              throw err if err
              pack()

  lessc = ->
    # Someone who knows CoffeeScript should make this more Coffee-licious
    console.log '   : Compiling LESS...'

    less.render(fs.readFileSync("src/main/less/screen.less", 'utf8')).then((output) ->
      fs.writeFileSync("src/main/html/css/screen.css", output.css))
    less.render(fs.readFileSync("src/main/less/reset.less", 'utf8')).then((output) ->
      fs.writeFileSync("src/main/html/css/reset.css", output.css)) 
    less.render(fs.readFileSync("src/main/less/bootstrap_include.less", 'utf8')).then((output) ->
      fs.writeFileSync("src/main/html/css/bootstrap.css", output.css))

    pack()

  pack = ->
    console.log '   : Packaging...'
    exec 'cp -r lib dist'
    console.log '   : Copied swagger-ui libs'
    exec 'cp -r node_modules/swagger-client/lib/swagger.js dist/lib'
    console.log '   : Copied swagger dependencies'
    exec 'cp -r node_modules/selectize/dist/js/standalone/selectize.min.js dist/lib'
    exec 'cp -r node_modules/selectize/dist/css/selectize.css dist/lib'
    console.log '   : Copied selectize dependencies'
    exec 'cp -r node_modules/select2/dist/js/select2.full.min.js dist/lib'
    exec 'cp -r node_modules/select2/dist/css/select2.min.css dist/lib'
    console.log '   : Copied select2 dependencies'
    exec 'rm -r dist/fonts/* || mkdir dist/fonts'
    exec 'cp -r node_modules/font-awesome/fonts/* dist/fonts'
    console.log '   : Copied fontawesome dependencies'
    exec 'cp -r src/main/html/* dist'
    console.log '   : Copied html dependencies'
    console.log '   !'

task 'spec', "Run the test suite", ->
  exec "open spec.html", (err, stdout, stderr) ->
    throw err if err

task 'watch', 'Watch source files for changes and autocompile', ->
  # Function which watches all files in the passed directory
  watchFiles = (dir) ->
    files = fs.readdirSync(dir)
    for file, index in files then do (file, index) ->
      console.log "   : " + dir + "/#{file}"
      fs.watchFile dir + "/#{file}", (curr, prev) ->
        if +curr.mtime isnt +prev.mtime
          invoke 'dist'

  notify "Watching source files for changes..."

  # Watch specific source files
  for file, index in sourceFiles then do (file, index) ->
    console.log "   : " + "src/main/coffeescript/#{file}.coffee"
    fs.watchFile "src/main/coffeescript/#{file}.coffee", (curr, prev) ->
      if +curr.mtime isnt +prev.mtime
        invoke 'dist'

  # watch all files in these folders
  watchFiles("src/main/template")
  watchFiles("src/main/javascript")
  watchFiles("src/main/html")
  watchFiles("src/main/less")
  watchFiles("src/test")

notify = (message) ->
  return unless message?
  console.log message
#  options =
#    title: 'CoffeeScript'
#    image: 'bin/CoffeeScript.png'
#  try require('growl') message, options
