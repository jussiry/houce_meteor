



Meteor.update_context = (func)->
  ctx = new Meteor.deps.Context() # invalidation context
  ctx.on_invalidate Meteor.update_context.bind null, func           # rerun update() on invalidation
  ctx.run func


# If you have model names with irregular pluralization,
# add the correct pluralization here
Houce.pluralize = (word)->
  models[word]?.plural or "#{word}s"


Houce.clear_models = ->
  for name, model_func of models
    log 'about to clear', name
    model_func.collection?.remove {}

Houce.clear_config = ->
  localStorage.removeItem 'config'
  localStorage.removeItem 'current_user_id'
  window.config = {}
  location.reload()

# configing reload estää model poistojen synkronoimisen...
# Houce.clear_all = ->
#   Houce.clear_models()
#   Houce.clear_config()


if Meteor.is_client

      # log 'MC: ', mc
      # mc.render 'idea', models.idea.collection.find().fetch()[0]

  # Print the current username to the console.  Will re-run every time
  # the username changes.
  # render_idea = ->
  #   update = ->
  #     ctx = new Meteor.deps.Context() # invalidation context
  #     ctx.on_invalidate(update)           # rerun update() on invalidation
  #     ctx.run ->
  #       log 'MC: ', mc
  #       mc.render 'idea', models.idea.collection.find().fetch()[0]
  #       #username = Session.get("username")
  #       #console.log("The current username is now", username)
  #   update()

  # render_idea()


  $.ajaxSetup
    async: true
    crossDomain: true
    dataType: 'json'
    #dataType: 'jsonp'
    contentType: "application/x-www-form-urlencoded; charset=utf-8"
    beforeSend: null #($jqxhr, params)-> $.ajaxStack.push $jqxhr
    error: (request, statustext, errormsg)->
      #unless errormsg == 'abort' or statustext == 'abort'
      #  alert "ajax error: #{statustext} :: #{errormsg}"

  # TODO: which is faster: .parents() or .contains() ? http://api.jquery.com/jQuery.contains/
  $.fn.is_in_dom = -> @parents('body').length > 0

  $.fn.outerHTML = (s)->
    if s
      @before(s).remove()
    else
      $("&lt;p&gt;").append(@eq(0).clone()).html()

  $.fn.cull = (selector)->
    filtered = @filter selector
    if filtered.length then filtered \
                       else @find selector

  $.fn.textWidth = ->
    qel = $ @
    if (orig_val = qel.val()).length
      # calculate value text length
      html_calc = '<span>' + orig_val + '</span>'
      qel.val html_calc
      width = qel.find('span:first').width()
      qel.html html_orig

    else
      # calculate text node length
      html_orig = qel.html()
      html_calc = '<span>' + html_orig + '</span>'
      qel.html html_calc
      width = qel.find('span:first').width()
      qel.html html_orig

    width



  #$.fn.animate_orig = $.fn.animate
  $.fn.anim = (args...)->
    merge args[0],
      useTranslate3d:  true
      leaveTransforms: true
    $.fn.animate.apply @, args

  # Retuns title of the current, or given page
  Houce.page_title = (templ)->
    page = Template[templ] if typeof templ is 'string'
    page ?= Pager.get_page()
    title = page.title or ''
    result_of title # title or title()


  do ->
    Houce.err_log = me = global.hel = (msg...)->
      msg = msg.map( (m)-> JSON.stringify m )
               .join ', '
      me.msgs.push msg
      log "HEL: #{msg}"
      me.msgs.shift() if me.msgs.length > 10
    me.msgs = []

  # # Send errors to server and show error notice to user
  # Houce.error = (error_str, file_path, line_number)->
  #   # skip known bugs
  #   return if error_str.matches [
  #     # "Script error." # Apparently caused by same origin policy: http://stackoverflow.com/questions/5913978/cryptic-script-error-reported-in-javascript-in-chrome-and-firefox
  #   ]  # or not Houce.error.logging_on

  #   log 'error_str', error_str
  #   log 'file_path', file_path

  #   # Show error message to user
  #   Template.notice.error (dict 'error_notice') or "Error!"  if Templates.notice?
  #   # Send to sever
  #   [title, msg...] = error_str.split ':'
  #   msg = msg.join ':'
  #   err_stack =  file_path?.split('/').last() or ''
  #   err_stack += ':' + line_number if line_number?
  #   $.post '/err_logs',
  #     ua:        navigator.userAgent
  #     err_title: title
  #     err_msg:   msg
  #     err_stack: err_stack
  #     err_logs:  Houce.err_log.msgs # JSON.stringify
  #     non_err_err:  JSON.stringify arguments
  #     timestamp:    Date.now()
  #     path_history: JSON.stringify Pager.path_history

