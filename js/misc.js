// Generated by CoffeeScript 1.4.0
(function() {
  var __slice = [].slice;

  Meteor.update_context = function(func) {
    var ctx;
    ctx = new Meteor.deps.Context();
    ctx.on_invalidate(Meteor.update_context.bind(null, func));
    return ctx.run(func);
  };

  Houce.pluralize = function(word) {
    var _ref;
    return ((_ref = models[word]) != null ? _ref.plural : void 0) || ("" + word + "s");
  };

  Houce.clear_models = function() {
    var model_func, name, _ref, _results;
    _results = [];
    for (name in models) {
      model_func = models[name];
      log('about to clear', name);
      _results.push((_ref = model_func.collection) != null ? _ref.remove({}) : void 0);
    }
    return _results;
  };

  Houce.clear_config = function() {
    localStorage.removeItem('config');
    localStorage.removeItem('current_user_id');
    window.config = {};
    return location.reload();
  };

  if (Meteor.is_client) {
    $.ajaxSetup({
      async: true,
      crossDomain: true,
      dataType: 'json',
      contentType: "application/x-www-form-urlencoded; charset=utf-8",
      beforeSend: null,
      error: function(request, statustext, errormsg) {}
    });
    $.fn.is_in_dom = function() {
      return this.parents('body').length > 0;
    };
    $.fn.outerHTML = function(s) {
      if (s) {
        return this.before(s).remove();
      } else {
        return $("&lt;p&gt;").append(this.eq(0).clone()).html();
      }
    };
    $.fn.cull = function(selector) {
      var filtered;
      filtered = this.filter(selector);
      if (filtered.length) {
        return filtered;
      } else {
        return this.find(selector);
      }
    };
    $.fn.textWidth = function() {
      var html_calc, html_orig, orig_val, qel, width;
      qel = $(this);
      if ((orig_val = qel.val()).length) {
        html_calc = '<span>' + orig_val + '</span>';
        qel.val(html_calc);
        width = qel.find('span:first').width();
        qel.html(html_orig);
      } else {
        html_orig = qel.html();
        html_calc = '<span>' + html_orig + '</span>';
        qel.html(html_calc);
        width = qel.find('span:first').width();
        qel.html(html_orig);
      }
      return width;
    };
    $.fn.anim = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      merge(args[0], {
        useTranslate3d: true,
        leaveTransforms: true
      });
      return $.fn.animate.apply(this, args);
    };
    Houce.page_title = function(templ) {
      var page, title;
      if (typeof templ === 'string') {
        page = Template[templ];
      }
      if (page == null) {
        page = Pager.get_page();
      }
      title = page.title || '';
      return result_of(title);
    };
    (function() {
      var me;
      Houce.err_log = me = global.hel = function() {
        var msg;
        msg = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        msg = msg.map(function(m) {
          return JSON.stringify(m);
        }).join(', ');
        me.msgs.push(msg);
        log("HEL: " + msg);
        if (me.msgs.length > 10) {
          return me.msgs.shift();
        }
      };
      return me.msgs = [];
    })();
  }

}).call(this);
