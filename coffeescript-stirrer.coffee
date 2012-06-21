# coffeescript-stirrer.coffee
#
# Extends the functionality of coffeescript to allow for inclusion of files.
#
util = require('util')
fs = require('fs')
http = require('http')
url = require('url')
path = require('path')
coffee = require('coffee-script')

INCLUDE_REGEX = /#=\s*include\s+<([^>\r\n]*)>/g
HTTP = /^http/
COFFEE_FILE = /\.coffee$/
JS_FILE = /\.js$/


showError = (message) ->
  console.error "\t----------------------------------------------------------------------"
  console.error "\t#{message}"
  console.error "\t----------------------------------------------------------------------"

# The dependency is on a remote server.  Download the file.
downloadFile = (file, callback) ->
  siteUrl = url.parse(file)
  remote = http.createClient(80, siteUrl.hostname)
  # Add an error handler
  remote.on('error', ((socketException) ->
    callback(null))
  )

  file = ''
  # If an error occurs we return a null.
  request = remote.request('GET', siteUrl.pathname ,{'host': siteUrl.hostname });
  request.on('response',
    ((response) ->

      if (response.statusCode + 0) == 200
        process.stdout.write("\t Downloading File: [ #{siteUrl.pathname} ] ")
        response.on('data', ((chunk) ->
          file += chunk
          # Print a marker to show that we are processing something.
          process.stdout.write(".");
        ))

        response.on('end', ( ->
          process.stdout.write(" OK \n")
          callback(file)
        ))

      else
        callback(null)
    ))
  request.end()

# Search through a file, given as a string and find the dependencies marked by
# #= include <FileName>
#
findIncludes = (file, contents, _resolved) ->
  _resolved ?= {}
  contents = '\n' + contents

  dependencies = []
  while (result = INCLUDE_REGEX.exec(contents)) != null
    depending_file = result[1]
    # console.log("File: [#{file}] requires <-- [#{depending_file}]")
    if JS_FILE.test(depending_file) then ftype = "js"
    if COFFEE_FILE.test(depending_file) then ftype = "coffee"
    remote=HTTP.test(depending_file)
    record = {
      file: depending_file
      ftype: ftype
      remote: remote
    }
    # Did we already cache this.
    cached = (d for d in _resolved when d.file == depending_file)
    # Just cache it.
    if cached.length == 0
      dependencies.push(record)
    else
      # Retrieve from cache.
      dependencies.push(cached[0])
  return dependencies

# Retrieve a list which is unique.
getUniqueList = (list, key) ->
  map = {}
  for item in list
    unless map[item[key]]?
      map[item[key]] = item

  (value for key, value of map)


resolveDependencies = (dependencies, includeDirectories, callback, results) ->
  # This is the first time we are running this.
  unless results?
    results = []
    # Make a unique list.
    dependencies =  getUniqueList(dependencies, "file")


  addDependencyAndContinue = (dependency) ->
    results.push(dependency)
    # Add this to the resolved dependencies.
    resolveDependencies(dependencies, includeDirectories, callback, results)

  if dependencies.length > 0
    dependency = dependencies.shift()
    if dependency.remote
      # The dependency might already have been loaded in the case of a watch.
      if dependency.data?
        console.log("\t Dependency #{dependency.file} has already been downloaded.  Retrieved from cache.  ")
        addDependencyAndContinue(dependency)
      else
        downloadFile(dependency.file, ( (data)->
          # We have retrieved the file.
          if data?
            # Add this to the dependency list.
            dependency.data = data
            addDependencyAndContinue(dependency)
          else
            showError "\tDependency: #{dependency.file} could not be retrieved.  [REMOTE]"
            callback(results, true)
        ))
    else
      found = false
      for directory in includeDirectories
        for file in fs.readdirSync(directory)
          # TODO: Make Unique FileName *--- Directory
          if path.basename(file) == dependency.file
            dependency.data = fs.readFileSync(directory + file)
            addDependencyAndContinue(dependency)
            found = true
            break

      unless found
        showError "\tERROR: Dependency: #{dependency.file} could not be retrieved.  [LOCAL]"
        callback(results, true)
  else
    # We are done.
    callback(results, false)

# Return an array of all files we could possibly include.
getIncludeCandidates = (sourceFiles, searchDirectories) ->
  files = sourceFiles
  for dir in searchDirectories
    files = files.concat(dir + f for f in fs.readdirSync(dir))
  return files

# remove all #= include directives from the source files.
removeDirectives = (file) ->
  fileDirectiveRegex = INCLUDE_REGEX
  file = file.replace(fileDirectiveRegex, '')
  return file

getFilename = (file, ext) ->
  return path.basename(file, ext)

recursiveIncludes = (includeDirectories) ->
  results = includeDirectories
  for directory in includeDirectories
      unless directory[directory.length-1] == ('/')
        directory += '/'
      files = fs.readdirSync(directory)
      # Check which of them are directories.
      for file in files
        stat = fs.lstatSync(directory + file)
        if stat .isDirectory()
          localResult = recursiveIncludes([directory + file])
          for local in localResult
            unless local[local.length-1] == ('/')
              local += '/'
            results.push(local)
  results

processcommand = (sourceFiles, includeDirectories, outputDir, compile, watch, _dependencies) ->
  compilation+=1
  #console.log("Compilation Epoch: #{compilation}")
  #console.log("----------------------------------------------------")

  for file in sourceFiles
    contents = fs.readFileSync(file)
    dependencies = findIncludes(file, contents, _dependencies)

    # The solved dependencies.
    compileFile = (file, dependencies) ->

      filename = getFilename(file, ".coffee")
      output_file = outputDir + filename + "_tmp.coffee"
      js_file = outputDir + filename + ".js"

      # Create the contents of the file.
      # console.log("Preparing Temporal File #{output_file}. #{dependencies.length} Dependencies Found.  ")

      buffer = "`// Preprocessed using Coffee-Stirrer v1.0 `\n\n"
      for dependency in dependencies
        # console.log("\tInjecting #{dependency.file} [#{dependency.ftype}]")
        # Determine whether the javascript file or a coffee script file.
        if dependency.ftype == "js"
          buffer += "`"  + dependency.data + "`\n\n"
        else
          buffer += dependency.data + "\n\n"

      buffer += contents
      buffer = removeDirectives(buffer)
      f = fs.writeFileSync(output_file, buffer)

      js_buffer = ""
      try
        dependencyString = ""
        for dependency in dependencies
          dependencyString += dependency.file + " "

        console.log("coffee-stirrer: compiling File #{file} -> #{js_file}. [#{dependencyString}] [#{compilation}]")

        nodes = coffee.nodes(coffee.tokens(buffer));
        js_buffer = nodes.compile()
        f = fs.writeFileSync(js_file, js_buffer)
      catch err
        showError(err)

      # Remove the temporary file
      fs.unlinkSync(output_file)

    resolveDependencies(dependencies,includeDirectories, ((solvedDependencies, error) ->
      #console.log ""
      #console.log("#{solvedDependencies.length} Dependencies for File #{file} resolved. ")
      #console.log ""
      if watch
        fs.watchFile(file, { persistent: true, interval: 1}, ((curr, prev) ->
          if curr.mtime.toString() != prev.mtime.toString()
            # Compile the file.
            processcommand([file], includeDirectories, outputDir, true, false, solvedDependencies)
        ))

      if compile and !error
        compileFile(file, dependencies)
        console.log("")
    ))

args = process.argv[2..]
unless args.length > 0
  console.log('Usage: coffee coffeescript-stirrer.coffee [-I .]* [-w] [-c] a.coffee')
  process.exit(1)

includeDirectories = []
sourceFiles = []

readingFlags = true
compile=false
watch=false
outputDir = ""
compilation = 0
i = 0
while readingFlags and i < args.length
  # Include this directory.
  if args[i] == '-I' or args[i] == '--include-dir'
    i++
    dir = args[i++]
    unless dir[dir.length-1] == ('/')
      dir += '/'
    # console.log("Added Directory [#{dir}] to search path.  [RECURSIVE] ");
    includeDirectories.push(dir)

  else if args[i] == '-c' or args[i] == '--compile'
    i++
    compile = true

  else if args[i] == '-w' or args[i] == '--watch'
    i++
    watch = true

  else if args[i] == '-o' or args[i] == '--output'
    i++
    outputDir = args[i++]
    unless outputDir[outputDir.length-1] == ('/')
      outputDir += '/'
  else
    readingFlags = false

#console.log("""
#====================================================
#COFFEE STIRRER Version 1.0
#====================================================
#Options:
#----------------------------------------------------
#  Compilation Flag: [#{compile}]"
#  Watch Flag:  [#{watch}]"
#  Output Directory: [#{outputDir}]"
#""");

while i < args.length
  sourceFiles.push(args[i++])

unless sourceFiles.length > 0
  console.log('Please supply at least 1 source files to run.  ')
  process.exit(1)

# Recursively include every directory. Still quite raw.
includeDirectories = recursiveIncludes(includeDirectories)
# Process the command thus merging and downloading the file.
processcommand(sourceFiles, includeDirectories, outputDir, compile, watch)
