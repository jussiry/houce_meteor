
# Pager watches browsers URL's hash and changes the page when the hash changes.
#
# When page is changes:
#
# * old page template gets `close` event.
# * new page template is initialized.
# * new page template gets `open` event.


# TODO: throw error if continue_callback called twice in @close
#       (by adding counter to path_history?)


global.Pager = do ->

  hashbang = '#/'
  bang     = '/'



  # The paradigm used in houCe for making singleton objects is to execute function (do ->)
  # with private variables defined above and public vars defined below by
  # returning a literal object.
  # Use 'me' inside public methods to refer to self and try to avoid using 'this' (@).
  me =

  #path_str:     null # full path string, e.g.  'list/deals/map/category=4'
  page_name:    null # arr with page name and basic path params
  path_stack:   [] # array of previous path strings
  path_history: [] # array of all previous path strings
  back_path:    null # temp var for back button

  # TODO: create invalidation contexes for each param
  # Does this require Params.get to be used as callback?
  # E.g. Pager.get 'plaa', (plaa_val)-> ...
  params:
    all:      ext() # 'key=value' path params
    contexes: ext()
    get: (key)->
      # add current context to be invalidated, if this parameter get changed
      if (ctx = Meteor.deps.Context.current)?
        ctx_cont = me.params.contexes[key] ?= ext()
        ctx_cont[ctx.id] = ctx
      # return parameter
      return me.params.all[key] if me.params.all[key]?
      for k,v of me.params.all
        return true if k.parsesToNumber() and v is key
      null
    set: (key, new_val)->
      if new_val?
        me.params.all[key] = new_val #.toPrimitive()
      else
        # when no value given, set key as value to index, e.g. /map/
        cur_ind = 0
        for k,v of me.params.all
          # search if param already exists
          if k.parsesToNumber()
            cur_ind += 1
            return if v is key
        # new param, set to next_ind
        me.params.all[cur_ind.toNumber()] = key
      me.check_if_params_changed()
      me.params.invalidate key
    preset: (key, val)->
      me.set(key, val) unless me.params.all[key]?
    remove: (key)->
      delete me.params.all[key]
      for k,v of me.params.all
        delete me.params.all[k] if k.parsesToNumber() and v is key
      me.check_if_params_changed()
      me.params.invalidate key
    toggle: (key, new_val)->
      if me.params.get key then me.params.remove key \
                           else me.params.set key, new_val
    invalidate: (param_key)->
      log 'params invalidate:', param_key
      # invalidate contexes
      me.params.contexes[param_key]?.values (ctx)->
        ctx.invalidate()
      delete me.params.contexes[param_key]

  path: ->
    if is_blank(last = me.path_history.last()) then me.main_page else last


  start_url_checking: (path)->
    me.open_page path:path if path
    # init hash checker
    window.onhashchange = Pager.check_url_hash
    Pager.check_url_hash()

    # unless Modernizr.hashchange # TODO android 2.1 claims to have but don't work: http://caniuse.com/hashchange ?
    #   #alert 'onhashchange '+location.hash
    #   else
    #   #alert 'check interval '+location.hash
    #   setInterval Pager.check_url_hash, 100

  get_page: -> Template[me.page_name] or me.main_page


  path_from_page_and_params: (page=me.page_name, params = me.params.all)->
    key_str = key_val_str = ''

    for k,v of params
      if k.parsesToNumber() then key_str     += "/#{v}"      \
                            else key_val_str += "/#{k}=#{v}"
    page + key_str + key_val_str


  page_and_params_from_path: (path_str)->
    if path_str?.has '/'
      params_arr = path_str.split('/').remove (e)-> is_blank e
      page_name = params_arr.shift()
      params = {}
      non_key_param_ind = 0
      for el in params_arr
        [key_or_val, val] = el.split '='
        if val?
          params[key_or_val] = val #.toPrimitive()
        else
          params[non_key_param_ind] = key_or_val #.toPrimitive()
          non_key_param_ind += 1
      [page_name, params]
    else
      [path_str, {}]

  # event
  check_if_params_changed: ->
    location.hash = hashbang + (path = me.path_from_page_and_params())
    if path isnt me.path_history.last()
      if me.path_stack.last().split('/')[0] is path.split('/')[0]
        # page is same, only params changed
        me.path_stack.splice -1, 1, path
      me.path_history.push path
      me.params_changed_event()

  # TODO: this is not DRY!
  # Is this needed anymore since we have params invalidating context?
  params_changed_event: ->
    return # TURNED OFF; TODO: remove open_page, this, and related functions
    return unless (active_tmpls = Houce.active_templates.keys()).map(
      (tmpl_name)-> Template[tmpl_name].events?.params
    ).compact().length
    Template[me.page_name].events?.params?
    # compare to old params to see what's changed
    [old_page, old_params] = me.page_and_params_from_path(Pager.path_history.at -2)
    changed_params = {}
    if old_page isnt me.page_name
      for k,v of me.params.all
        changed_params[k] = v
        changed_params[v] = true if k.parsesToNumber() and typeof v isnt 'number'
    else
      # check for new params:
      for k, cur_val of me.params.all
        if cur_val isnt old_params[k]
          changed_params[k] = cur_val
          changed_params[cur_val] = true if k.parsesToNumber()
      # check for removed params:
      for k, old_val of old_params
        if old_val? and not me.params.all[k]?
          changed_params[k] = false
          changed_params[old_val] = false if k.parsesToNumber() and typeof v isnt 'number'

    for tmpl_name in active_tmpls
      Template[tmpl_name].events.params? changed_params
      #Template[me.page_name].events.params changed_params


  go_back: (default_prev, steps=1)->
    steps.times -> me.path_stack.pop() # pop current path
    if me.path_stack.length
      me.back_path = me.path_stack.pop() # pop prev_path
      history.go -steps
    else
      me.open_page path: (default_prev or me.main_page)
    return false


  # Gets executed evrytime window.locatio.hash changes.
  check_url_hash: ->
    hash = window.location.hash # shorthands
    if hash[0..1] isnt hashbang
      # direct to main page
      return window.location.hash = bang + me.main_page

    new_path_str = hash[2..-1]

    # Check if hash path has changed
    return if new_path_str is me.path_history.last()

    [page, params] = me.page_and_params_from_path new_path_str

    if me.back_path?
      # back_button pressed, open previous page:
      me.open_page path: me.back_path
      me.back_path = null
    else if page isnt me.page_name
      # page changed, open new page
      me.open_page page:page, params:params
    else if not equal params, me.params.all
      # remove old changed/removed params
      for old_key,old_val of me.params.all
        unless params[old_key] is old_val
          me.remove old_key
      # set new params
      for key,val of params
        me.set key, val

  # open_page args:
  #   path    # string of new_path, overwrites 'page' and 'params'
  #   page    # name of new page
  #   params  # params to new page
  #   already_closed  # used to avoid page.close from looping forever
  open_page: (args)->
    if not args? # refresh page
      args = path: Pager.path()
    else if typeof args is 'string'
      args = path: args
    if args.path?
      if args.path[0] is '#'
        args.path = args.path.split('/')[1..-1].join '/'
      [args.page, args.params] = me.page_and_params_from_path args.path

    # close old page if event exists:
    if (old_page = Template[me.page_name])?.close? and not args.already_closed
      return old_page.close (me.open_page.bind me, (merge args, already_closed:true)), \
                            args.page, args.params

    # update path vars
    me.page_name  = args.page
    me.params.all = args.params
    # push to path_history
    me.path_history.push new_path=me.path_from_page_and_params()
    # remove from stack if already there and add again
    if (i = me.path_stack.indexOf new_path) isnt -1
      me.path_stack = me.path_stack.to i
    me.path_stack.push new_path
    # update url to new_path (already updated if coming from check_url_hash)
    location.hash = bang + new_path #unless Utils.device.browser is 'IE'

    me.before_open_page()
    error = null

    if (templ = Template[me.page_name])?
      log 'templ', templ
      if templ.html?
        Pager.tmpl_container.html Houce.render_spark me.page_name
      else
        error = "<strong>'#{me.page_name}' has not defined @open, @params_changed or @html function and thus can't be executed.</strong>"
      # alway fire also params_changed event with open_page (assuming there are some params)
      me.params_changed_event()
    else
      log "WARNING: #{me.page_name}.templ not found!" if Houce.log_events
      error = "Template <strong>#{me.page_name}.templ</strong> not found!"

    $('body').html error if error?

    me.after_open_page()


# TODO: change params back to root level properties
# and remove these temporary hack
Pager.get    = Pager.params.get
Pager.set    = Pager.params.set
Pager.preset = Pager.params.preset
Pager.remove = Pager.params.remove
Pager.toggle = Pager.params.toggle
