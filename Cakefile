

fs           = require 'fs'
{exec}       = require 'child_process'
#CoffeeScript = require 'coffee-script'

#require 'sugar'

Array.prototype.last  = -> @[@.length-1]
Array.prototype.first = -> @[0]

# HELPERS

log = -> console.log.apply console, arguments #.bind console

execute = do ->
  exec_stack = []
  do_exec = ->
    command = exec_stack[0]
    exec command, (err, stdout, stderr)->
      if err?
        console.log "error with #{command}:"
        console.log stderr
      if stdout?
        console.log stdout
      console.log "#{command}"
      exec_stack.shift()
      do_exec() if exec_stack.length
  return (command)->
    exec_stack.push command
    # start execution(s), if this is the first one
    do_exec() if exec_stack.length is 1

for_files_in = (path, file_func)->
  (iterator = (path)->
    folder_contents = fs.readdirSync path
    for file_or_folder in folder_contents
      fof_path = "#{path}/#{file_or_folder}"
      fof_stat = fs.statSync fof_path
      if fof_stat.isDirectory()
        iterator fof_path
      else
        return if file_func(fof_path) is false
    return
  )( path )


# TASKS

task 'compile', ->
  for_files_in './coffee', (path)->
    if path.split('.').slice(-1)[0] is 'coffee'
      execute "coffee -o ./js -c #{path}"
      # ...and always when changed
      fs.watchFile path, (interval: 300), (cur,prev)->
        if cur.size isnt prev.size
          # TODO: danger, won't compile if character amount won't change?
          execute "coffee -o ./js -c #{path}"
          console.log path + ' cahnged!'


task 'start', ->
  invoke 'watch_houce'
  execute "meteor run -p 3007"





# houce compile helper
meteor_folder = null
compile_and_copy_to_package = (c_path)->
  log 'c_path', c_path
  # compile and move js files to package dir
  f_name = c_path.split('/').last().split('.').first()
  execute "coffee -o .houce/js -c #{c_path}" # ./apis.coffee
  #execute "coffee -c #{c_path} -o #{js_path}"
  js_path = ".houce/js/#{f_name}.js"
  #js_path = c_path.replace '.coffee', '.js'
  execute "cp -f #{js_path} /usr/#{meteor_folder}/meteor/packages/houce/#{js_path.split('/')[-1..-1]}"


task 'compile_houce', (p)->
  meteor_folder = p.arguments[1] or 'local' # could also be 'lib'
  # make sure houce package folder exits
  execute "mkdir -p /usr/#{meteor_folder}/meteor/packages/houce"

  for_files_in '.houce', (path)->
    switch path.split('.')[-1..-1][0]
      when 'js'
        execute "cp -f #{path} /usr/#{meteor_folder}/meteor/packages/houce/#{path.split('/')[-1..-1]}"
      when 'coffee'
        # compile and copy all in start
        compile_and_copy_to_package path


#option '-i', '--folder [PEM]', 'path to key file'
option '-f', '--folder [DAA]', 'meteor folder'
task 'watch_houce', 'watch and compile .houce folder', (options)->
  log 'running watch_houce, with options:', options #p.arguments[1]
  log 'options.folder' ,options.folder
  log 'options.key' ,options.key
  meteor_folder = options.folder or 'local' # could also be 'lib'
  # make sure houce package folder exits
  execute "mkdir -p /usr/#{meteor_folder}/meteor/packages/houce"

  for_files_in '.houce', (path)->
    log 'path in watch houce: '+path
    switch path.split('.')[-1..-1][0]
      when 'js'
        #execute "mv -f #{path} /usr/local/meteor/packages/houce/#{path.split('/')[-1..-1]}"
        execute "cp -f #{path} /usr/#{meteor_folder}/meteor/packages/houce/#{path.split('/')[-1..-1]}"
      when 'coffee'
        # compile and copy all in start
        compile_and_copy_to_package path
        # ...and always when changed
        fs.watchFile path, (interval: 300), (cur,prev)->
          if cur.size isnt prev.size
            # TODO: danger, won't compile if character amount won't change?
            compile_and_copy_to_package path
            console.log path + ' cahnged!'

