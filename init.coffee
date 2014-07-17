

# if window?
#   @global = window


# ### Main modules: ###

# # Namespace for houCe functions
# global.Houce  = ext()
# # Namespace for models
# global.models = ext()
# # Namespace for utility libraries
# global.utils  = ext()
# # Namespace for configs
# global.config = ext()
# # Namespace for templates
# global.template = template ? ext()




# # Setup houCe. Called from setup.coffee

# Houce.init_houce = (args)->

#   global.Data ?= {}

#   CCSS?.initTemplates()

#   defaults =
#     data_structure: {}
#     data_version: 1
#     config:
#       storage_on: true
#     error_logging: false

#   args = merge defaults, args

#   ### Config ###

#   merge config, args.config
#   prev_config = JSON.parse (localStorage.config or '{}')
#   if (v = prev_config.version)? and v is config.version
#     merge config, prev_config

#   $(window).bind 'unload', ->
#     localStorage.config = JSON.stringify config

#   # Test local storage:
#   try
#     # In iphone/ipad private mode this will fail
#     for store in [localStorage, sessionStorage]
#       store.storage_test = 'works'
#   catch err then config.storage_on = false

#   ### Init templates ###


#   ### Namespacing to store all modules under single application object ###
#   global[config.app_name] =
#     config: config
#     houce:  Houce
#     models: models
#     utils:  utils
#     #Templates: Templates


#   ### Init application ###

#   unless window.ERROR
#     # execute app specific init
#     args.init_app?()
#     # start pager
#     pager.start_url_checking()
