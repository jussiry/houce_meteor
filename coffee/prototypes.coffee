

@global = window if window?

# http://sugarjs.com/objects#object_extend
#if Meteor.is_server
# Object.extend() # if Object.defineProperty?
# delete Object.prototype.isObject # conflicts with CoffeeScript compiler
# delete Object.prototype.isFunction


prototypes =

  Array:
    get_num:  -> for el in @
      return el if el.constructor is Number
    get_str:  -> for el in @
      return el if el.constructor is String
    get_arr:  -> for el in @
      return el if el.constructor is Array
    get_func: -> for el in @
      return el if el.constructor is Function
    get_bool: -> for el in @
      return el if el.constructor is Boolean

  Number:
    toDate: -> Date.create(@)
    getPrecision: ->
      (@+'').split(".")[1]?.length or 0
    is_in: (arr)-> arr.some @valueOf()


  String:
    is_in: (arr)-> arr.some @valueOf()
    parsesToNumber: ->
      not Object.isNaN this - 0  #this.toNumber()
    toPrimitive: ->
      str = ''+@
      return throw "'#{str}'.toPrimitive() has illegal characters." if str.matches ['=', '(', '{']
      if      str.parsesToNumber()              then str.toNumber()
      else if str.matches ['true', 'false', 'null'] then eval str
      else str
    # Same as .is_in, except check also for partial strings
    # e.g. "baad".matches['aa'] # true
    matches: (strings)->
      return null unless typeof strings is 'object' # typeof strings is 'array' or
      for own k,str of strings
        #log 'str -'+str+'-', str.length, is_blank str
        return true if (@.match (''+str).escapeRegExp()) and str isnt ''
      false
    # Enhanced split that uses numbers to split based on index
    # split: (delim)->
    #   log 'ROTO'. @__proto__
    #   if typeof delim is 'number' then return [@slice(0,delim), @slice(delim)] \
    #                               else @orig_split(delim)

if Object.defineProperty?
  for type, functions of prototypes
    for func_name, func of functions
      if global[type].prototype[func_name]?
        # store original function, if exists
        p = global[type].prototype
        p[func_name+'_orig'] = p[func_name]
      # define new method
      Object.defineProperty global[type].prototype, func_name, (value: func)
else
  throw "Object.defineProperty not supported!"

# # Mask Object.prototype properties in global object
# for property_name in Object.prototype
#   global[property_name] = undefined unless global.hasOwnProperty(property_name)

if Object.defineProperty?
  # Extend Sugar's extended objects
  hash_extensions =
    # creates a child of object called upon
    child: (child={}) ->
      child.__proto__ = @
      child
    first:  -> Object.values(@)[0]
    # forEach: can be used both on arrays and objects
    # each with value,key instad of key-values. ({}|[]).each (val, key)->
    forEach: (func)-> Object.each @, (key,val)-> func(val,key)
    has_own: (prop_name)-> @.hasOwnProperty(prop_name) and @[prop_name] isnt null
    # Chek if primitive is found in array or in object (as top level value)
    # e.g.  if some_str.is_in ['aa', 'bb', 'cc'] then ...
    # NOTE: works only for primitives, not objects!
    is_in: (arr_or_obj)->
      for own k,v of arr_or_obj
        return true if @+'' is v+'' and typeof v isnt 'object'
      false
    length: -> Object.keys(@).length
    # map values based on function
    map: (map_func)->
      for key,val of @
        @[key] = map_func val, key
      @
    own_properties: ->
      o = {}
      for name in Object.getOwnPropertyNames(@)
        o[name] = @[name]
      o
    # return an array with __proto__ parents of object
    proto_parents: ->
      parents = []
      cur_obj = @
      while (cur_obj = cur_obj.__proto__)? and parents.length < 10
        parents.push cur_obj
      parents
    remove: (test_func)->
      for key, val of @
        delete obj[key] if test_func key, val
      obj
  # add hash_extensions to hash proto
  hash_proto = Object.extended().__proto__
  for func_name, func of hash_extensions
    Object.defineProperty hash_proto, func_name, (value: func)


