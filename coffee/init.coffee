

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

  Pager.main_page        = config.main_page or args.main_page # TODO deprecate args.main_page
  Pager.before_open_page = args.before_open_page
  Pager.after_open_page  = args.after_open_page
  # if Meteor.is_client
  #   Houce.init_data.app_defaults = args.data_structure
  #   Houce.init_data.version      = args.data_version


  ### Error logging to server ###
  # requires (Redis) data storage; currently not implemented on server

  # Houce.error.logging_on = args.error_logging
  # window.onerror = Houce.error


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
    localStorage  .storage_test = 'works'
    sessionStorage.storage_test = 'works'
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
    Pager.tmpl_container = $(config.tmpl_container or args.tmpl_container or 'body')
    # execute app specific init
    args.init_app()
    # start Pager
    Pager.start_url_checking()
