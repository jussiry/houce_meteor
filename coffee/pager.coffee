
# pager.watches browsers URL's hash and changes the page when the hash changes.
#
# When page is changes:
#
# * old page template gets `close` event.
# * new page template is initialized.
# * new page template gets `open` event.


# TODO: throw error if continue_callback called twice in @close
#       (by adding counter to path_history?)


global.pager = do ->

  hashbang = '#/'
  bang     = '/'

  # The paradigm used in houCe for making singleton objects is to execute function (do ->)
  # with private variables defined above and public vars defined below by
  # returning a literal object.
  # Use 'me' inside public methods to refer to self and try to avoid using 'this' (@).
  me =

  #path_str:     null # full path string, e.g.  'list/deals/map/category=4'
  path_stack:   [] # array of previous path strings
  path_history: [] # array of all previous path strings
  back_path:    null # temp var for back button

  page_name:
    str: null
    dependency: new Deps.Dependency
    get: ->
      Deps.depend @dependency
      @str
    set: (newStr)->
      unless newStr is @str
        @str = newStr
        @dependency.changed()

  params:
    all:          ext() # 'key=value' path params
    dependencies: ext()
    get: (key)->
      # create dependency to be invalidated, if this parameter get changed
      me.params.dependencies[key] ?= new Deps.Dependency
      Deps.depend me.params.dependencies[key]
      # return parameter
      return me.params.all[key] if me.params.all[key]?
      for k,v of me.params.all
        return key if k.parsesToNumber() and v is key
      null
    set: (key, new_val, skip_history)->
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
      me.check_if_params_changed(skip_history)
      me.params.dependencies[key]?.changed()
    preset: (key, val)->
      me.params.set(key, val) unless me.params.all[key]?
    remove: (key, skip_history)->
      delete me.params.all[key]
      for k,v of me.params.all
        delete me.params.all[k] if k.parsesToNumber() and v is key
      me.check_if_params_changed(skip_history)
      me.params.dependencies[key]?.changed()
    toggle: (key, new_val, skip_history)->
      if me.params.get key then me.params.remove key, skip_history \
                           else me.params.set key, new_val, skip_history

  path: ->
    if is_blank(last = me.path_history.last()) then me.main_page else last


  start_url_checking: (main_page)->
    if main_page?
    then me.main_page = main_page
    else console.warn "Main page not given to pager.start_url_checking; don't know what to do on '/' url"
    # init hash checker
    window.onhashchange = pager.check_url_hash
    pager.check_url_hash()

    # unless Modernizr.hashchange # TODO android 2.1 claims to have but don't work: http://caniuse.com/hashchange ?
    #   #alert 'onhashchange '+location.hash
    #   else
    #   #alert 'check interval '+location.hash
    #   setInterval pager.check_url_hash, 100

  path_from_page_and_params: (page=me.page_name.str, params = me.params.all)->
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
  check_if_params_changed: (skip_history)->
    location.hash = hashbang + (path = me.path_from_page_and_params())
    unless path is me.path_history.last() or skip_history
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
      (tmpl_name)-> template[tmpl_name].events?.params
    ).compact().length
    template[me.page_name.str].events?.params?
    # compare to old params to see what's changed
    [old_page, old_params] = me.page_and_params_from_path(pager.path_history.at -2)
    changed_params = {}
    if old_page isnt me.page_name.str
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
      template[tmpl_name].events.params? changed_params
      #template[me.page_name.str].events.params changed_params


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

    [page, new_params] = me.page_and_params_from_path new_path_str

    if me.back_path?
      # back_button pressed, open previous page:
      me.open_page path: me.back_path
      me.back_path = null
    else if page isnt me.page_name.str
      # page changed, open new page
      me.open_page page:page, params:new_params
    else if not equal new_params, me.params.all
      # remove old changed/removed params
      for old_key,old_val of me.params.all
        unless new_params[old_key]? #and new_par isnt old_val and not
          me.remove old_key
      # set new params
      for key,val of new_params
        me.set key, val
        # if key.parsesToNumber()
        # then me.set val
        # else me.set key, val

  # open_page args:
  #   path    # string of new_path, overwrites 'page' and 'params'
  #   page    # name of new page
  #   params  # params to new page
  #   already_closed  # used to avoid page.close from looping forever
  open_page: (args)->
    if not args? # refresh page
      args = path: pager.path()
    else if typeof args is 'string'
      args = path: args
    if args.path?
      if args.path[0] is '#'
        args.path = args.path.split('/')[1..-1].join '/'
      [args.page, args.params] = me.page_and_params_from_path args.path

    # close old page if event exists:
    # if (old_page = template[me.page_name.str])?.close? and not args.already_closed
    #   return old_page.close (me.open_page.bind me, (merge args, already_closed:true)), \
    #                         args.page, args.params

    # update path vars
    me.page_name.set args.page

    # TODO: make reactive style instead of params_changed_event!
    me.params.all = args.params # shouldn't this also make reactive change?
    me.params_changed_event()

    # push to path_history
    me.path_history.push new_path=me.path_from_page_and_params()
    # remove from stack if already there and add again
    if (i = me.path_stack.indexOf new_path) isnt -1
      me.path_stack = me.path_stack.to i
    me.path_stack.push new_path

    # update url to new_path (already updated if coming from check_url_hash)
    location.hash = bang + new_path #unless Utils.device.browser is 'IE'



# TODO: change params back to root level properties
# and remove these temporary hack
pager.get    = pager.params.get
pager.set    = pager.params.set
pager.preset = pager.params.preset
pager.remove = pager.params.remove
pager.toggle = pager.params.toggle
