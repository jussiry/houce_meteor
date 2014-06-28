

if window?
  @global = window


### Main modules: ###

# Namespace for houCe functions
global.Houce  = ext()
# Namespace for models
global.models = ext()
# Namespace for utility libraries
global.utils  = ext()
# Namespace for configs
global.config = ext()
# Namespace for templates
global.Template = Template ? ext()


global.delay = (ms, func)->
  if Object.isFunction ms then ms.delay() \
                          else func.delay ms


# Setup houCe. Called from setup.coffee

Houce.init_houce = (args)->

  global.Data ?= {}

  CCSS?.initTemplates()

  defaults =
    main_page: null
    before_open_page: ->
    after_open_page:  ->
    data_structure: {}
    data_version: 1
    config:
      # TOOD: use insted Zepto or some other library for mobile stuff?
      #is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
      storage_on: true
    layout:
      wrapper: ''
    init_app:  ->
    error_logging: false

  args = merge defaults, args

  pager.main_page        = config.main_page or args.main_page # TODO deprecate args.main_page
  pager.before_open_page = args.before_open_page
  pager.after_open_page  = args.after_open_page

  ### Config ###

  merge config, args.config
  prev_config = JSON.parse (localStorage.config or '{}')
  if (v = prev_config.version)? and v is config.version
    merge config, prev_config

  $(window).bind 'unload', ->
    localStorage.config = JSON.stringify config

  # Test local storage:
  try
    # In iphone/ipad private mode this will fail
    for store in [localStorage, sessionStorage]
      store.storage_test = 'works'
  catch err then config.storage_on = false

  ### Init templates ###
  Houce.init_templates()

  ### Namespacing to store all modules under single application object ###
  global[config.app_name] =
    config: config
    houce:  Houce
    models: models
    utils:  utils
    #Templates: Templates


  ### Init application ###

  unless window.ERROR
    # layout  TODO: deprecate args.layout and args.tmpl_container
    $('body').html Houce.parse_template (config.layout or args.layout)
    pager.tmpl_container = $(config.tmpl_container or args.tmpl_container or 'body')
    # execute app specific init
    args.init_app()
    # start pager
    pager.start_url_checking()
