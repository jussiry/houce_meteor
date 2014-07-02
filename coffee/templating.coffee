
# Package.register_extension "XXX", ->
#   log 'REGISTERING XXX!!!'

if Meteor.isClient # TODO: Why is this loaded on sever when package says 'client'?
  # CURRENTLY NOT IN USE, temporalily 'el' is a global function
  Houce.template_helpers =
    el: (el_type, content)->
      (o = {})[el_type] = content
      o
    add: (html_obj)->
      # TODO ...
      Houce.tmpl_iterator html_obj
      # for key, el of html_obj
      #   Houce.tmpl_stack.last().push Houce.combine_tag_arr [ Houce.create_html_node(key), el ]
      #   #Houce.tmpl_stack.last().push html_obj
      return

  Houce.init_templates = ->
    for templ_name, container of Template
      # bind name of template under each template
      do ->
        c = container
        container.name = templ_name
        container.render = -> Houce.parse_template c.html # HTML.Raw
        container.blaze_component = UI.Component.extend(container)
    return

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

  Houce.parse_template = (html_obj_or_func)->
    #log 'html_obj_or_func', html_obj_or_func

    html_obj = if typeof html_obj_or_func is 'function' then html_obj_or_func.call(Houce._cur_data) \
                                                        else html_obj_or_func
      # log 'IS FUNCTION', html_obj_or_func.toString() #, Houce.template_helpers
      # `with( Houce.template_helpers ){
      #   var func_str = html_obj_or_func.toString();
      #   html_obj = eval(func_str);
      # }`

    Houce.tmpl_stack = [ [] ] # 'body'

    Houce.tmpl_iterator html_obj #, (data or {})
    #log 'FINAL HTML', Houce.tmpl_stack[0].join ''
    #debugger
    #debugger
    Houce.tmpl_stack[0].map (el)-> if typeof el is 'string' then HTML.Raw el else el #.join ''

  do ->

    Houce.tmpl_iterator = iterate = (el, key)->
      return unless el?
      if not key?
        # new object, iterate through all childs
        throw "unexpected type in tmpl array #{el}" unless typeof el is 'object' # TYPE CHECK, remove for performance gain
        if el instanceof Array
          for sub_el in el
            (iterate sub_el) #, data
        else
          (iterate sub_el, sub_key) for sub_key, sub_el of el # key is el when 1 argument
      else                    # , data
        key = key.split('%')[0]
        if typeof el is 'function'
          el = el.call(Houce._cur_data) #Houce.add_helper_funcs el, data
        if key[0] is '_'
          # attribute value
          Houce.tmpl_stack.last().tag_attrs ?= {} # store element attributes to the element array
          Houce.tmpl_stack.last().tag_attrs[key[1..-1]] = el
        # else if key.matches ['text', 'txt']
        #   # raw 'el' value without tag wrapper
        #   Houce.tmpl_stack.last().push el
        else if key is 'me'
          if typeof el is 'object' then iterate el \ # , data
                                   else Houce.tmpl_stack.last().push el
        else
          if key is 'render'
            stack_store = Houce.tmpl_stack
            data = Houce._cur_data
            #log 'ABOUT to render partial: ',el
            [el, data] = el if el instanceof Array
            Houce.tmpl_stack.last().push Template[el].blaze_component #Houce.render_blaze_partial el, data
            Houce.tmpl_stack = stack_store
            Houce._cur_data  = data # return correct data context, if changed by sub templates
            #log 'Partial rendered successfully: ',el
          else
            switch typeof el #el.constructor
              when 'object'
                Houce.tmpl_stack.push [k = Houce.parse_html_tag key]
                if el instanceof Array then (iterate sub_el) for sub_el in el \ # , data
                                       else iterate el #, data
                Houce.tmpl_stack.at(-2).push Houce.combine_tag_arr Houce.tmpl_stack.pop()
              when 'string', 'number'
                Houce.tmpl_stack.last().push Houce.combine_tag_arr [ Houce.parse_html_tag(key), el ]
      return

  Houce._cur_data = null

  Houce.parse_html_tag = (str, hash_format)->
    element  = 'div'
    id       = null
    classes  = []
    # allow use of empty spaces by interpreting them as '_'
    str = str.replace(/\s/g, '_')
    # change i_plaa to '#plaa' and c_plaa to '.plaa'
    str = str.replace(/(^|_)(c_|\.)/g, '.').replace(/(^|_)(i_|#)/g, '#') #(^| |,)
    # Element
    unless str[0].matches ['#', '.']
      ends = if (e = str.search(/[.#]/) - 1) is -2 then -1 else e
      element = str[0..ends]
    # ID
    if id_arr = str.match /#[^.#$]*/
      id = id_arr[0][1..-1]
      #log 'id -'+id+'-'
    # Classes
    ((str.match /\.[^.#$]*/g) or []).each (c)->
      classes.push c[1..-1]

    if hash_format
      element: element
      id:      id
      classes: classes
    else
      id = "id='#{id}'" if id
      classes = if classes.length then "class='#{classes.join ' '}'" else null
      "<#{element} #{ifs id,id} #{ifs classes,classes}>"

  Houce.combine_tag_arr = (arr, parent)->
    # add attributes
    if arr.tag_attrs? #Houce.tmpl_tag_attributes.keys().length
      non_class_add = false
      for attr_name, attr of arr.tag_attrs #Houce.tmpl_tag_attributes
        if attr_name is 'class' and (i = arr[0].search 'class=') isnt -1
          # class already defined in key, add to it
          arr[0] = arr[0].insert attr+' ', i+7
        else
          arr[0] = arr[0][0..-2] + " #{attr_name}='#{attr}' "
          non_class_add = true
      arr[0] += '>' if non_class_add
      #log 'tag:',arr[0] if Houce.tmpl_tag_attributes.keys().length
      #Houce.tmpl_tag_attributes = {}
    # check first element and close by adding to end
    element = arr[0].match(/\<.+?(\s|>)/)[0][1..-2]
    arr.push "</#{element}>"
    arr.join '' # HTML.Raw

  Houce.render_blaze = (tmpl_or_name)-> # , extra_data
    Houce.sub_tmpls_rendered = 0
    Houce.current_main_tmpl = tmpl_or_name
    Houce.current_parent_comp = null
    # html_func = Spark.render ->
    #   Houce.render_blaze_partial tmpl_or_name
    res = Houce.render_blaze_partial tmpl_or_name
    console.log "partial result ", res
    Houce._cur_data = null
    res

  Houce.render_blaze_partial = (tmpl_or_name, data)->
    Houce.sub_tmpls_rendered += 1
    throw "Too deep template stack in '#{Houce.current_main_tmpl}'! Probably endless loop." if Houce.sub_tmpls_rendered > 100
    # `data` possible only for handlebar templates
    tmpl = if typeof tmpl_or_name is 'object' then tmpl_or_name \
                                              else Template[tmpl_or_name]
    unless tmpl?
      throw "Template not found: #{tmpl_or_name}"
    #console.log 'rendering: '+tmpl.name

    if tmpl.blaze_component? # tmpl.html?
      #rc = (UI.render(c = UI.Component.extend({render:function(){return "plaa"}})))
      rendered_comp = if tmpl.data?
      then console.log "rendering with data not implemented!" #UI.renderWithData tmpl.blaze_component, tmpl.data() #, Houce.current_parent_comp
      else UI.render tmpl.blaze_component #, Houce.current_parent_comp
      # houce template
      # html = Spark.labelBranch Meteor.uuid(), -> # tmpl.name+'-'+Meteor.uuid() # (''+Math.random())[2..-1]
      #   html = Spark.createLandmark (tmpl.events or {}), (landmark)->
      #     html = Spark.isolate ->
      #       if tmpl.data?
      #         Houce._cur_data = if typeof tmpl.data is 'function' then tmpl.data() \
      #                                                             else tmpl.data
      #       html = Houce.parse_template tmpl.html #, Houce._cur_data
      #       html
      # html = Spark.attachEvents tmpl.events, html if typeof tmpl.events is 'object'
      # html = Spark.setDataContext tmpl.data, html if tmpl.data?
    else if typeof tmpl is 'function' # handelbar templates
      # handlebars template
      rendered_comp = new Handlebars.SafeString tmpl data
      rendered_comp
    else
      return alert 'unknown template!'
    #log 'HTML', global.rendered_comp = rendered_comp if tmpl.name is 'dev_editor'
    rendered_comp

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


