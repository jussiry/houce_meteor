
if window?
  @global = window


# NAMESPACINC
# TODO: load namespace.coffee through packages.(js|json) once Meteor 0.9 is released
# Namespace for houCe functions
global.Houce  = Object.extended()
# Namespace for models
global.models = Object.extended()
# Namespace for utility libraries
global.utils  = Object.extended()
# Namespace for configs
global.config = Object.extended()
# Namespace for templates
global.template = template ? Object.extended()


# DEFINE GLOBALS, later bind to actual global

globals =

  callbacks: (args...)->
    if args.length is 2
      # args: [async_func_1, af2, ...], final_cb
      async_funcs = args[0]
      final_cb    = args[1]
    else
      # args: async_func_1, af2, ..., final_cb
      final_cb    = args.pop()
      async_funcs = args[0]

    af_responses = []

    # executed after all async_funcs are ready:
    af_ready = (->
      #final_cb.apply null, af_responses
      final_cb af_responses
    ).after async_funcs.length

    for af, ind in async_funcs
      do ->
        i = ind
        af_callback = (res)->
          af_responses[i] = res
          af_ready()
        if typeof af is 'function'
          af af_callback
        else if Object.isArray af
          # af is [af, param1, param2, ...]
          params = af
          af     = params.shift()
          params = params.concat af_callback
          af.apply null, params
        else
          throw "Illegal asyn_func param for callbacks"
    return

  # Calls given function with given 'this'
  # params: this, [arg1, ...], func
  call_with: ->
    if arguments.length is 2
      arguments[1].call arguments[0]
    else
      args = Array.prototype.slice.call arguments
      args[args.length-1].apply args[0], args[1..-2]


  # child() creates a new object that inherits from the given object
  child_of: (parent, child={})->
    child.__proto__ = parent
    child

  dir: (args...) -> console.dir.apply console, args

  # calls given function with given arguments
  # params: arg1, arg2, ..., func
  do_with: (args...)-> args.pop().apply args.last(), args

  delay: (ms,func)->
    if Object.isFunction ms then ms.delay() \
                            else func.delay ms

  # WORK ON PROCESS
  # Allows dynamic scope by
  # creating function call using @ as 'with' param
  dynamic: (scope_or_func, func)->
    if arguments.length is 2
      log 'calling with scopre', scope_or_func
      `with(scope_or_func){ func(); }`
    else
      `with(this){ scope_or_func(); }`
    return
    # func_str = CoffeeScript.parse func, bare:true # from """ #   (function(){ #     this.daa = 34 #     plaa() #   })() # """ # to """ #   (function(){ #     this.daa = 34 #     with(this){ plaa() } #   })() # """

  # Sugar.js Object shorthands:
  each:  Object.each #(a,b)-> Object.each a, b #.bind Object
  equal: Object.equal
  ext:   Object.extended

  # Short version for returning the value (normally string)
  # if argument exists, otherwise returns empty string:
  ifs: (arg, true_str, false_str)->
    true_str = arg unless true_str?
    if arg then true_str else (if false_str? then false_str else '')

  is_blank: (obj)-> not obj? or (Object.isString(obj) and /^\s*$/.test obj) \
                                     or (typeof object is 'object' and Object.keys(obj).length == 0)

  ins: (o)->
    str = "#{o.constructor.name} (#{typeof o}):\n"
    str += "#{key}: #{val},\n" for own key,val of o

  keys:   Object.keys

  log: (args...) -> console.log.apply console, args

  merge: Object.merge

  # Prototype way of creating new- or merging to existing object.
  # Merging only possible when two or three args
  named_obj: do ->
    # Create named functions for name proto objects
    func_cache = {}
    get_func = (name)->
      if (f = func_cache[name])?
      then f
      else eval 'func_cache[name] = function '+name+'(){}'
    # Hash object as the top parent
    hash_proto = Object.extended().__proto__
    # actual proto_obj function:
    return (args...)->
      switch args.length
        when 1 # properties
          obj = args[0]
        when 2 # name, properties
          container  = global
          obj_name   = args[0]
          properties = args[1]
        when 3 # container, name, properties
          container  = args[0]
          container  = global[container] if typeof container is 'string'
          obj_name   = args[1]
          properties = args[2]
        else
          throw "named_obj: too many arguments"
      if args.length > 1
        container[obj_name] = obj =
          if   container[obj_name]? \
          then merge container[obj_name], properties
          else properties
        obj.constructor = get_func obj_name
        obj.name = obj_name
      # finally, we have 'obj', now initialize it!
      if obj.parent?
        child_of obj.parent, obj
        delete   obj.parent
      else
        child_of hash_proto, obj
      obj.init?()
      # if obj.init?
      #   delete obj.init
      #Object.freeze obj
      obj

  # JS shorhands
  qs:  document?.querySelector.bind document
  qsa: document?.querySelectorAll.bind document

  result_of: (a)->
    if typeof a is 'function' then a() else a

  # merge multiple 'this' objects for function call
  this_is: (args...)->
    # args: this_obj, this_obj2, ..., function
    this_obj = args[0]
    for arg in args[1..-2]
      this_obj.merge arg # if typeof arg is 'object'
    args.last().call this_obj

  # Typecheck for all objects
  # (exceptions: NaN and Infinity -> 'number')
  type: (arg)->
    return 'array' if arg instanceof Array
    return 'null'  if arg is null
    typeof arg

  # returns an array with push and shift methods that destory equal elements
  uniq: (arr)->
    arr.__proto__ = Array.prototype
    arr.unshift = (new_el)->
      arr.remove new_el # removes all elements, not very fast
      Array.prototype.unshift.call @, new_el
    arr.push = (new_el)->
      arr.remove new_el # removes all elements, not very fast
      Array.prototype.push.call @, new_el
    arr

  values: Object.values


# BIND FUNCTIONS TO GLOBAL
for name, func of globals
  global[name] = func


# SPECIAL GLOBAL DEFS:

# Make deep copy of object
global.clone ?= (obj)-> Object.clone obj, true

# alias for JQuery
q = $ if $?


# OBJECT GLOBALS

Object.remove_els = (obj, test_func)-> # using Object.prototype.remove would fuck things up properly; no idea why
  (delete obj[key] if test_func key, val) for key, val of obj
  obj

Object.filter = (obj, test_func)->
  new_obj = {}
  for key, val of obj
    new_obj[key] = val if test_func key, val
  new_obj

RegExp.quote = (str)-> (str+'').replace /([.?*+^$[\]\\(){}|-])/g, "\\$1"

# if Object.getPrototypeOf?
#   # Hmm, not so sure if this really works
#   Object.setPrototypeOf = (obj, proto)-> # IE 9, chrome, moz
#     p = proto
#     loop
#       p = Object.getPrototypeOf p
#       throw Error('Circular prototype chain') if obj is p

#     obj.__proto__ = proto # # hmmmm....


