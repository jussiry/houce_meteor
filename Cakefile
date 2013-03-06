

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

