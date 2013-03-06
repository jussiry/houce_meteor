
#require = __meteor_bootstrap__.require
fs = require 'fs'
CS = require 'coffee-script'

path = require 'path'

console.log path.dirname() #,' ',__dirname

packages_path = process.execPath.split('/')[0..-3].join('/')+'/packages'

for file_name in ['sugar-1.3.8.min', 'globals', 'prototypes']
  try require "#{packages_path}/houce/#{file_name}"
  catch err
    console.log "#{packages_path}/houce/#{file_name}, #{err}"

Package.describe
  summary: "houCe template system in Meteor"


Package.on_use (api)->
  # load ccss_helpers
  ccss_path = process.env.PWD+'/styles/ccss_helpers.coffee'
  ccss_str = fs.readFileSync(ccss_path).toString()
  try CS.eval ccss_str
  catch err
    error "compiling ccss_helpers: ", err

  files =
    both: [
      'sugar-1.3.8.min'
      #'coffeekup' # 'coffeecup'
      'prototypes'
      'globals'
      'init'
      'misc'
    ]
    client: [
      #'apis'
      'pager'
      'templating'
    ]
    server: []

  for place, file_arr of files
    for file in file_arr
      api.add_files "#{file}.js", if place is 'both' then ['client', 'server'] \
                                                          else place
  return



error = do ->
  css_added = false
  (strs...)->
    error_strs = ["\nERROR "]
    (error_strs.push str) for str in strs
    error_strs.push "\n"
    # Log error on server
    console.log error_strs.join ''
    # Send error to client
    if error.bundle?
      unless css_added
        error.bundle.add_resource
          type: "css"
          path: '/error.css'
          data: "#site_error { margin: 2% 1%; }"
          where: 'client'
        css_added = true
      error.bundle.add_resource
        type: "js"
        path: '/error.js'
        data: """(function(){
            var error_strs = #{JSON.stringify(error_strs)};
            document.write("<div id='site_error'>"+error_strs.join('<br/>')+"</div>");
            window.ERROR = true;
            throw error_strs.join('');
          })()
        """
        where: 'client'


ccss = do ->

  extend = (object, properties) ->
    for key, value of properties
      object[key] = value
    object

  compile: (rules) ->
    css = ''

    for selector, pairs of rules
      declarations = ''
      nested = {}

      #add mixins to the current level
      for mix_name in ['me', 'mixins']
        if pairs[mix_name]
          for mixin in [].concat pairs[mix_name]
            extend pairs, mixin
          delete pairs[mix_name]


      #a pair is either a css declaration, or a nested rule
      for key, value of pairs
        if typeof value is 'object'
          children = []
          split = key.split /\s*,\s*/
          children.push "#{selector} #{child}" for child in split
          nested[children.join ','] = value
        else
          #borderRadius -> border-radius
          key = key.replace /[A-Z]/g, (s) -> '-' + s.toLowerCase()
          declarations += "  #{key}: #{value};\n"

      declarations and css += "#{selector} {\n#{declarations}}\n"

      css += @compile nested

    css

  shortcuts: (obj)->
    for orig_key, val of obj
      ccss.shortcuts val if typeof val is 'object'
      # split multi definitions:
      keys = orig_key.split(/,|___/).map('trim')
      keys.each (k)->
        # change i_plaa to '#plaa' and c_plaa to '.plaa'
        k = k.replace(/^c_/g, '.').replace(/^i_/g, '#') #(^| |,)
        k = k.replace(/_c_/g, '_.').replace(/_i_/g, '_#')
        # change #plaa_.daa (orig: i_plaa_c_daa) to '#plaa.daa'
        k = k.replace(/_\./g, '.').replace(/_#/, '#')
        # font_size to font-size
        if typeof val isnt 'object'
          k = k.replace(/_/g,'-')
        # change number values to pixels
        non_pixel_vars = ['font-weight', 'opacity', 'z-index', 'zoom']
        val = "#{val}px" if typeof val is 'number' and non_pixel_vars.none k # not k.is_in non_pixel_vars
        # set new key and delete old:
        if typeof val is 'object'
          obj[k] ?= {}
          merge obj[k], val
        else
          obj[k] = val
        if k isnt orig_key
          delete obj[orig_key]
    obj

Package.register_extension "templ", (bundle, source_path, serve_path, where)->
  console.log "processing TMPL #{source_path[18..-1]}" # .remove '/Users/jussir/code'

  error.bundle = bundle

  #current_dir = process.env.PWD
  templ_name = source_path.split('/').last().replace '.templ', ''
  file_str = fs.readFileSync(source_path).toString().trim() # trim file_str to make style_regexp bit simpler

  # add $n (where n = 1..n) to end of key when many keys have same name
  # to avoid losing key value pairs with same key.
  found_els = {}

  # PREPROCESS @html and @style functions
  # remove comments
  file_str = (for row in file_str.split '\n'
    if row.has(/^\s+\#/) then null else row
                         #else row.replace /#[^\'\"]*$/, ''
  ).compact().join '\n'
  # log 'without comments\n', file_str
  # add/modify function calls where needed:
  cur_type = null
  new_rows = []
  json_row = /^\s+('|"|[^\s]+\s*:)/ # *($|#)
  func_row = /^\s+[^'"\s][^\s:]*\s+[^:\s]/  # /(=|for |return |if |unless )/
  (rows = file_str.split '\n').each (row, ind)->
    # change type if @xxx row
    if row.has /^@/
      cur_type = row[1...(row.search /[\s\=]/)]
      # make @html function, if it's not already
      if cur_type is 'html' and not row.has '->'
        row = row.replace /\=/, '= ->'
    # process when under @html or @style
    else if cur_type is 'html' or cur_type is 'style'
      if cur_type is 'html' and row.has(json_row)
        # check for multiple keys, change to key%n when needed
        key = row.split(':')[0].trim().remove(/'|"/g)
        if found_els[key]?
          found_els[key] += 1
          row = row.replace key, "'#{key}%#{found_els[key]}'"  #/%\d+/, ''
        else found_els[key] = 1
      # for both @html and @style:
      if row.has(json_row)
        # add function wrapped call if next row has function operations
        if rows[ind+1]?.has func_row
          row = row.replace ':', ': do =>'
      else
        # '->' to 'do =>'
        row = row.replace /:\s*->/, ': do =>'
    new_rows.push row
  file_str = new_rows.join '\n'

  # if templ_name is 'left_nav'
  #  log '---------------------\n\nafter processing', file_str

  # STYLE
  style_regexp = /// @style        # begins with @style
                    (.|\n)*?       # anything, but:
                    ($|            # end of file, or
                    \n(?!\s)) ///g # new line followed by anything else than intendation.

  style_str = (file_str.match style_regexp)?[0] # )? #, ()->
  #log 'Houce.ccss', Houce.ccss
  if style_str?
    #log '---------STYLE---------'
    #log style_str
    try
      style_js = result_of CS.compile style_str, bare:true
      `with( Houce.ccss ){
        var style = eval(style_js);
      }`
      style = result_of style
    catch err
      error "when parsing @style of #{templ_name}.templ\n#{err}"
      return
    ccss.shortcuts style
    try css = ccss.compile style
    catch err
      error "\nERROR in compiling @style in template: #{templ_name}.#{file_extension}: #{err}"
      return

    if css.length
      bundle.add_resource
        type: "css"
        path: serve_path.replace '.templ', '.css'
        data: css
        where: where

    file_str = file_str.remove style_regexp.addFlag 'g'


  try templ_js = CS.compile file_str, bare:true
  catch err
    error "in compiling '#{source_path}'\n#{err}"
    return
  templ_js = "if( Meteor.is_client ){ Template.#{templ_name} = new function(){\n#{templ_js} } }" #\nreturn this;\n


  bundle.add_resource
    type: "js"
    path: serve_path.replace '.templ', '.js'
    data: templ_js
    where: where

Package.register_extension "plaa", (bundle, source_path, serve_path, where)->
  console.log "processing PLAA #{source_path[18..-1]} for test" # .remove '/Users/jussir/code'


Package.register_extension "ccss", (bundle, source_path, serve_path, where)->
  console.log "processing CCSS #{source_path[18..-1]}" # .remove '/Users/jussir/code'
  error.bundle = bundle
  file_str = fs.readFileSync(source_path).toString().trim() # trim file_str to make style_regexp bit simpler
  try
    style_js = result_of CS.compile file_str, bare:true
    `with( Houce.ccss ){
      var style = eval(style_js);
    }`
    style = result_of style
  catch err
    error "in parsing #{source_path}\n#{err}"
    return
  ccss.shortcuts style
  try css = ccss.compile style
  catch err
    error "\nERROR in compiling @style in template: #{templ_name}.#{file_extension}: #{err}"
    return

  bundle.add_resource
    type: "css"
    path: serve_path.replace '.ccss', '.css'
    data: css
    where: where
