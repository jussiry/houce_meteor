// Generated by CoffeeScript 1.4.0
(function() {

  if (Meteor.is_client) {
    Houce.template_helpers = {
      el: function(el_type, content) {
        var o;
        (o = {})[el_type] = content;
        return o;
      },
      add: function(html_obj) {
        Houce.tmpl_iterator(html_obj);
      }
    };
    Houce.init_templates = function() {
      var container, templ_name;
      for (templ_name in Template) {
        container = Template[templ_name];
        container.name = templ_name;
      }
    };
    Houce.parse_html_tag = function(str, hash_format) {
      var classes, e, element, ends, id, id_arr;
      element = 'div';
      id = null;
      classes = [];
      str = str.replace(/\s/g, '_');
      str = str.replace(/(^|_)(c_|\.)/g, '.').replace(/(^|_)(i_|#)/g, '#');
      if (!str[0].matches(['#', '.'])) {
        ends = (e = str.search(/[.#]/) - 1) === -2 ? -1 : e;
        element = str.slice(0, +ends + 1 || 9e9);
      }
      if (id_arr = str.match(/#[^.#$]*/)) {
        id = id_arr[0].slice(1);
      }
      ((str.match(/\.[^.#$]*/g)) || []).each(function(c) {
        return classes.push(c.slice(1));
      });
      if (hash_format) {
        return {
          element: element,
          id: id,
          classes: classes
        };
      } else {
        if (id) {
          id = "id='" + id + "'";
        }
        classes = classes.length ? "class='" + (classes.join(' ')) + "'" : null;
        return "<" + element + " " + (ifs(id, id)) + " " + (ifs(classes, classes)) + ">";
      }
    };
    Houce.combine_tag_arr = function(arr) {
      var attr, attr_name, element, i, non_class_add, _ref;
      if (arr.tag_attrs != null) {
        non_class_add = false;
        _ref = arr.tag_attrs;
        for (attr_name in _ref) {
          attr = _ref[attr_name];
          if (attr_name === 'class' && (i = arr[0].search('class=')) !== -1) {
            arr[0] = arr[0].insert(attr + ' ', i + 7);
          } else {
            arr[0] = arr[0].slice(0, -1) + (" " + attr_name + "='" + attr + "' ");
            non_class_add = true;
          }
        }
        if (non_class_add) {
          arr[0] += '>';
        }
      }
      element = arr[0].match(/\<.+?(\s|>)/)[0].slice(1, -1);
      arr.push("</" + element + ">");
      return arr.join('');
    };
    Houce.add_helper_funcs = function(orig_func, data) {
      var new_func_str;
      new_func_str = "with( Houce.template_helpers ){ return (" + (orig_func.toString()) + ").call(data); }";
      return Function(new_func_str);
    };
    Houce.parse_template = function(html_obj_or_func) {
      var html_obj;
      html_obj = typeof html_obj_or_func === 'function' ? html_obj_or_func.call(Houce._cur_data) : html_obj_or_func;
      Houce.tmpl_stack = [[]];
      Houce.tmpl_iterator(html_obj);
      return Houce.tmpl_stack[0].join('');
    };
    (function() {
      var iterate;
      return Houce.tmpl_iterator = iterate = function(el, key) {
        var data, k, stack_store, sub_el, sub_key, _base, _i, _j, _len, _len1, _ref, _ref1;
        if (el == null) {
          return;
        }
        if (!(key != null)) {
          if (typeof el !== 'object') {
            throw "unexpected type in tmpl array " + el;
          }
          if (el instanceof Array) {
            for (_i = 0, _len = el.length; _i < _len; _i++) {
              sub_el = el[_i];
              iterate(sub_el);
            }
          } else {
            for (sub_key in el) {
              sub_el = el[sub_key];
              iterate(sub_el, sub_key);
            }
          }
        } else {
          key = key.split('%')[0];
          if (typeof el === 'function') {
            el = el.call(Houce._cur_data);
          }
          if (key[0] === '_') {
            if ((_ref = (_base = Houce.tmpl_stack.last()).tag_attrs) == null) {
              _base.tag_attrs = {};
            }
            Houce.tmpl_stack.last().tag_attrs[key.slice(1)] = el;
          } else if (key === 'me') {
            if (typeof el === 'object') {
              iterate(el);
            } else {
              Houce.tmpl_stack.last().push(el);
            }
          } else {
            if (key === 'render') {
              stack_store = Houce.tmpl_stack;
              data = Houce._cur_data;
              if (el instanceof Array) {
                _ref1 = el, el = _ref1[0], data = _ref1[1];
              }
              Houce.tmpl_stack.last().push(Houce.render_spark_partial(el, data));
              Houce.tmpl_stack = stack_store;
              Houce._cur_data = data;
            } else {
              switch (typeof el) {
                case 'object':
                  Houce.tmpl_stack.push([k = Houce.parse_html_tag(key)]);
                  if (el instanceof Array) {
                    for (_j = 0, _len1 = el.length; _j < _len1; _j++) {
                      sub_el = el[_j];
                      iterate(sub_el);
                    }
                  } else {
                    iterate(el);
                  }
                  Houce.tmpl_stack.at(-2).push(Houce.combine_tag_arr(Houce.tmpl_stack.pop()));
                  break;
                case 'string':
                case 'number':
                  Houce.tmpl_stack.last().push(Houce.combine_tag_arr([Houce.parse_html_tag(key), el]));
              }
            }
          }
        }
      };
    })();
    Houce._cur_data = null;
    Houce.render_spark = function(tmpl_or_name) {
      var html_func;
      Houce.sub_tmpls_rendered = 0;
      Houce.current_main_tmpl = tmpl_or_name;
      html_func = Spark.render(function() {
        return Houce.render_spark_partial(tmpl_or_name);
      });
      Houce._cur_data = null;
      return html_func;
    };
    Houce.render_spark_partial = function(tmpl_or_name, data) {
      var html, tmpl;
      Houce.sub_tmpls_rendered += 1;
      if (Houce.sub_tmpls_rendered > 100) {
        throw "Too deep template stack in '" + Houce.current_main_tmpl + "'! Probably endless loop.";
      }
      tmpl = typeof tmpl_or_name === 'object' ? tmpl_or_name : Template[tmpl_or_name];
      if (tmpl == null) {
        throw "Template not found: " + tmpl_or_name;
      }
      if (tmpl.html != null) {
        html = Spark.labelBranch(Meteor.uuid(), function() {
          return html = Spark.createLandmark(tmpl.events || {}, function(landmark) {
            return html = Spark.isolate(function() {
              if (tmpl.data != null) {
                Houce._cur_data = typeof tmpl.data === 'function' ? tmpl.data() : tmpl.data;
              }
              html = Houce.parse_template(tmpl.html);
              return html;
            });
          });
        });
        if (typeof tmpl.events === 'object') {
          html = Spark.attachEvents(tmpl.events, html);
        }
        if (tmpl.data != null) {
          html = Spark.setDataContext(tmpl.data, html);
        }
      } else if (typeof tmpl === 'function') {
        html = new Handlebars.SafeString(tmpl(data));
        html;

      } else {
        return alert('unknown template!');
      }
      return html;
    };
  }

}).call(this);
