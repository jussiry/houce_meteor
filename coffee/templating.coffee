
if Meteor.isClient

  Houce.init_templates = ->
    # loop 'houce' (not Spacebars) templates
    for tmpl_name, tmpl of template when not tmpl.render?
      # bind name of template under each template
      tmpl.name = tmpl_name
      Template.__define__ tmpl_name,  do ->
        t = tmpl
        ->
          # wrapper function creates new Deps computation in matarialization stage
          => Houce.parse_template t, @ # e
      # add all template props to Meteor Template
      for prop_name, tmpl_prop of tmpl when prop_name isnt 'html'
        Template[tmpl_name][prop_name] = tmpl_prop
    return

  Houce.parse_template = (tmpl, component)->
    console.log "about to parse '#{tmpl.name}', (deps #{Deps.currentComputation?._id})"
    if typeof tmpl.html is 'function'
      # using 'vars' instead of Meteor 'data', since 'data' causes update too often (e.g. every time even is fired)
      data = component.vars?() ? {}
      component.templateInstance.vars = data
      html_obj = tmpl.html.call data #component
      # call 'updated' always after render; use execute data related ops
      setTimeout => component.vars_updated?.call data, component.templateInstance, component
    else
      html_obj = tmpl.html

    addToParent = (parent, node)-> # node: anything that can be materialized in UI.js
      if parent instanceof Array # root element
        parent.push node
      else if parent instanceof HTML.Tag
        parent.children = [] unless parent.hasOwnProperty 'children'
        parent.children.push node
      else throw "unknow type"

    iterate = (parent, val)->
      return parent unless val?
      if val instanceof Array
        for subnode in val
          (iterate parent, subnode) #, data
      else if typeof val is 'object'
        for key, subnode of val # key is val when 1 argument
          # check for special key (attributes, me, render)
          if key[0] is '_'
            # attribute value
            if parent instanceof Array
              throw "Can't set attributes for root list (#{key})"
            parent.attrs ?= {} # store element attributes to the element array
            parent.attrs[key[1..-1]] = subnode
          else if key.match /^me($|[^a-zA-Z])/
            iterate parent, subnode
          else if key.match /^render/
            #[subnode, data] = subnode if subnode instanceof Array
            unless Template[subnode]?
              throw "Template named '#{subnode}' not found!"
            addToParent parent, Template[subnode]
          else
            # "normal" key, create tag and iterate children
            tag = Houce.parse_html_tag key
            iterate tag, subnode
            addToParent parent, tag
      else
        addToParent parent, val
      return parent

    # parse the actual template
    try
      res = iterate root=[], html_obj
    catch err
      console.error "template parsing error ", err
      debugger
    res

  Houce.parse_html_tag = (str)->
    sElement  = 'DIV'
    id       = null
    classes  = []
    # allow use of empty spaces by interpreting them as '_'
    str = str.replace(/\s/g, '_')
    # change i_plaa to '#plaa' and c_plaa to '.plaa'
    str = str.replace(/(^|_)(c_|\.)/g, '.').replace(/(^|_)(i_|#)/g, '#') #(^| |,)
    # Element
    unless str[0].matches ['#', '.']
      ends = if (e = str.search(/[^a-zA-Z0-9]/) - 1) is -2 then -1 else e
      sElement = str[0..ends].toUpperCase()
      unless HTML[sElement]?
        throw "Unknown HTML tag '#{str[0..ends]}'"
    # ID
    if id_arr = str.match /#[^.#$]*/
      id = id_arr[0][1..-1]
    # Classes
    ((str.match /\.[^.#$]*/g) or []).each (c)->
      classes.push c[1..-1]

    # create HTML element
    el = HTML[sElement]()
    if classes.length then (el.attrs ?= {}).class = classes.join ' '
    if id?            then (el.attrs ?= {}).id = id
    el
    # if DOM_format # not used currently - for DOM (not string) based templates
    #   el = document.createElement sElement
    #   el.setAttribute 'class', classes
    #   el.id = id
    #   el
    # else if string_format
    #   id = "id='#{id}'" if id
    #   classes = if classes.length then "class='#{classes.join ' '}'" else null
    #   "<#{sElement} #{ifs id,id} #{ifs classes,classes}>"

  Houce.render_blaze = (tmpl_name, parentDomEl)-> # , extra_data
    tmpl = Template[tmpl_name]
    throw "Template not found: #{tmpl_or_name}" unless tmpl?
    #res = Blaze.toHTML tmpl
    #debugger
    UI.render tmpl #, parentDomEl

  # JQuery shortcuts for Houce.render
  jQuery.fn.render = (args...)->
    @html (el = Houce.render_blaze.apply null, args)
    el
  jQuery.fn.render_bottom = (args...)->
    @append (el = Houce.render_blaze.apply null, args)
    el
  jQuery.fn.render_top = (args...)->
    @prepend (el = Houce.render_blaze.apply null, args)
    el
  jQuery.fn.render_outer = (args...)->
    @first().before (el = Houce.render_blaze.apply null, args)
    @remove()
    el



    # Houce.combine_tag_arr = (arr)->
    # # add attributes
    # if arr.tag_attrs? #Houce.tmpl_tag_attributes.keys().length
    #   non_class_add = false
    #   for attr_name, attr of arr.tag_attrs #Houce.tmpl_tag_attributes
    #     if attr_name is 'class' and (i = arr[0].search 'class=') isnt -1
    #       # class already defined in key, add to it
    #       arr[0] = arr[0].insert attr+' ', i+7
    #     else
    #       arr[0] = arr[0][0..-2] + " #{attr_name}='#{attr}' "
    #       non_class_add = true
    #   arr[0] += '>' if non_class_add
    #   #log 'tag:',arr[0] if Houce.tmpl_tag_attributes.keys().length
    #   #Houce.tmpl_tag_attributes = {}
    # # check first element and close by adding to end
    # element = arr[0].match(/\<.+?(\s|>)/)[0][1..-2]
    # arr.push "</#{element}>"
    # arr.join '' #


    # receives nested array, e.g.
  # [ ['<div>','div text content'], ['<div>',[Component,['<span>','and another']]] ]
  # ->
  # ["<div>div text content</div>
  #   <div>
  #     ", Component, "
  #     <span>and another</span>
  #   </div>"]
  # Houce.parse_nested_array_tmpl = (nestedArr)->
  #   flatArr = ['']
  #   addToFlat = (el)->
  #     if typeof el is 'string' and typeof (last = flatArr.last()) is 'string'
  #     then flatArr.splice -1,1, last + el
  #     else flatArr.push el
  #   iterator = (nested)->
  #     if nested instanceof Array
  #       if typeof nested[0] is 'string' #and nested[1] instanceof Array
  #         addToFlat nested[0]
  #         iterator nested[1]
  #         element = nested[0].match(/\<.+?(\s|>)/)[0][1..-2]
  #         addToFlat "</#{element}>"
  #       else
  #         iterator el for el in nested
  #     else
  #       addToFlat nested
  #     return
  #   iterator nestedArr
  #   flatArr

  # CURRENTLY NOT IN USE, temporalily 'el' is a global function
  # Houce.template_helpers =
  #   el: (el_type, content)->
  #     (o = {})[el_type] = content
  #     o
  #   add: (html_obj)->
  #     # TODO ...
  #     Houce.tmpl_iterator html_obj
  #     # for key, el of html_obj
  #     #   Houce.tmpl_stack.last().push Houce.combine_tag_arr [ Houce.create_html_node(key), el ]
  #     #   #Houce.tmpl_stack.last().push html_obj
  #     return

  # HTML node creation with document.createElement
  # (stored here if need for kind of template appears)
    # Houce.create_html_node = (sKey)->
    #   throw "hash_format ?" if hash_format?
    #   element  = 'div'
    #   id       = null
    #   classes  = []
    #   # allow use of empty spaces by interpreting them as '_'
    #   sKey = sKey.replace(/\s/g, '_')
    #   # change i_plaa to '#plaa' and c_plaa to '.plaa'
    #   sKey = sKey.replace(/(^|_)(c_|\.)/g, '.').replace(/(^|_)(i_|#)/g, '#') #(^| |,)
    #   # Element
    #   unless sKey[0].matches ['#', '.']
    #     ends = if (e = sKey.search(/[.#]/) - 1) is -2 then -1 else e
    #     element = sKey[0..ends]
    #   # ID
    #   if id_arr = sKey.match /#[^.#$]*/
    #     id = id_arr[0][1..-1]
    #     #log 'id -'+id+'-'
    #   # Classes
    #   ((sKey.match /\.[^.#$]*/g) or []).each (c)->
    #     classes.push c[1..-1]
    #   # id = "id='#{id}'" if id
    #   # classes =  then "class='#{}'" else null
    #   # "<#{element} #{ifs id,id} #{ifs classes,classes}>"
    #   el = document.createElement element
    #   el.id = id if id?
    #   if classes.length
    #     el.setAttribute 'class', classes.join ' '
    #   el

