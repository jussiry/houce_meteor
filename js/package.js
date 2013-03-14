// Generated by CoffeeScript 1.4.0
(function() {
  var CS, ccss, error, file_name, fs, packages_path, path, _i, _len, _ref,
    __slice = [].slice;

  fs = require('fs');

  CS = require('coffee-script');

  path = require('path');

  console.log(path.dirname());

  packages_path = process.execPath.split('/').slice(0, -2).join('/') + '/packages';

  _ref = ['sugar-1.3.8.min', 'globals', 'prototypes'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    file_name = _ref[_i];
    try {
      require("" + packages_path + "/houce/" + file_name);
    } catch (err) {
      console.log("" + packages_path + "/houce/" + file_name + ", " + err);
    }
  }

  Package.describe({
    summary: "houCe template and page handling in Meteor"
  });

  Package.on_use(function(api) {
    var ccss_path, ccss_str, file, file_arr, files, place, _j, _len1, _ref1;
    ccss_path = process.env.PWD + '/styles/ccss_helpers.coffee';
    try {
      ccss_str = (_ref1 = fs.readFileSync(ccss_path)) != null ? _ref1.toString() : void 0;
      CS["eval"](ccss_str);
    } catch (err) {
      error("compiling ccss_helpers: ", err);
    }
    files = {
      both: ['sugar-1.3.8.min', 'prototypes', 'globals', 'init', 'misc'],
      client: ['pager', 'templating'],
      server: []
    };
    for (place in files) {
      file_arr = files[place];
      for (_j = 0, _len1 = file_arr.length; _j < _len1; _j++) {
        file = file_arr[_j];
        api.add_files("" + file + ".js", place === 'both' ? ['client', 'server'] : place);
      }
    }
  });

  error = (function() {
    var css_added;
    css_added = false;
    return function() {
      var error_strs, str, strs, _j, _len1;
      strs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      error_strs = ["\nERROR "];
      for (_j = 0, _len1 = strs.length; _j < _len1; _j++) {
        str = strs[_j];
        error_strs.push(str);
      }
      error_strs.push("\n");
      console.log(error_strs.join(''));
      if (error.bundle != null) {
        if (!css_added) {
          error.bundle.add_resource({
            type: "css",
            path: '/error.css',
            data: "#site_error { margin: 2% 1%; }",
            where: 'client'
          });
          css_added = true;
        }
        return error.bundle.add_resource({
          type: "js",
          path: '/error.js',
          data: "(function(){\n  var error_strs = " + (JSON.stringify(error_strs)) + ";\n  document.write(\"<div id='site_error'>\"+error_strs.join('<br/>')+\"</div>\");\n  window.ERROR = true;\n  throw error_strs.join('');\n})()",
          where: 'client'
        });
      }
    };
  })();

  ccss = (function() {
    var extend;
    extend = function(object, properties) {
      var key, value;
      for (key in properties) {
        value = properties[key];
        object[key] = value;
      }
      return object;
    };
    return {
      compile: function(rules) {
        var child, children, css, declarations, key, mix_name, mixin, nested, pairs, selector, split, value, _j, _k, _l, _len1, _len2, _len3, _ref1, _ref2;
        css = '';
        for (selector in rules) {
          pairs = rules[selector];
          declarations = '';
          nested = {};
          _ref1 = ['me', 'mixins'];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            mix_name = _ref1[_j];
            if (pairs[mix_name]) {
              _ref2 = [].concat(pairs[mix_name]);
              for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                mixin = _ref2[_k];
                extend(pairs, mixin);
              }
              delete pairs[mix_name];
            }
          }
          for (key in pairs) {
            value = pairs[key];
            if (typeof value === 'object') {
              children = [];
              split = key.split(/\s*,\s*/);
              for (_l = 0, _len3 = split.length; _l < _len3; _l++) {
                child = split[_l];
                children.push("" + selector + " " + child);
              }
              nested[children.join(',')] = value;
            } else {
              key = key.replace(/[A-Z]/g, function(s) {
                return '-' + s.toLowerCase();
              });
              declarations += "  " + key + ": " + value + ";\n";
            }
          }
          declarations && (css += "" + selector + " {\n" + declarations + "}\n");
          css += this.compile(nested);
        }
        return css;
      },
      shortcuts: function(obj) {
        var keys, orig_key, val;
        for (orig_key in obj) {
          val = obj[orig_key];
          if (typeof val === 'object') {
            ccss.shortcuts(val);
          }
          keys = orig_key.split(/,|___/).map('trim');
          keys.each(function(k) {
            var non_pixel_vars, _ref1;
            k = k.replace(/^c_/g, '.').replace(/^i_/g, '#');
            k = k.replace(/_c_/g, '_.').replace(/_i_/g, '_#');
            k = k.replace(/_\./g, '.').replace(/_#/, '#');
            if (typeof val !== 'object') {
              k = k.replace(/_/g, '-');
            }
            non_pixel_vars = ['font-weight', 'opacity', 'z-index', 'zoom'];
            if (typeof val === 'number' && non_pixel_vars.none(k)) {
              val = "" + val + "px";
            }
            if (typeof val === 'object') {
              if ((_ref1 = obj[k]) == null) {
                obj[k] = {};
              }
              merge(obj[k], val);
            } else {
              obj[k] = val;
            }
            if (k !== orig_key) {
              return delete obj[orig_key];
            }
          });
        }
        return obj;
      }
    };
  })();

  Package.register_extension("tmpl", function(bundle, source_path, serve_path, where) {
    var css, cur_type, file_str, found_els, func_row, json_row, new_rows, row, rows, style, style_js, style_regexp, style_str, tmpl_js, tmpl_name, _ref1;
    console.log("processing TMPL " + (source_path.remove(process.env.PWD)));
    error.bundle = bundle;
    tmpl_name = source_path.split('/').last().replace(/\.tmpl$/, '');
    file_str = fs.readFileSync(source_path).toString().trim();
    found_els = {};
    file_str = ((function() {
      var _j, _len1, _ref1, _results;
      _ref1 = file_str.split('\n');
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        row = _ref1[_j];
        if (row.has(/^\s+\#/)) {
          _results.push(null);
        } else {
          _results.push(row);
        }
      }
      return _results;
    })()).compact().join('\n');
    cur_type = null;
    new_rows = [];
    json_row = /^\s+('|"|[^\s]+\s*:)/;
    func_row = /^\s+[^'"\s][^\s:]*\s+[^:\s]/;
    (rows = file_str.split('\n')).each(function(row, ind) {
      var key, _ref1;
      if (row.has(/^@/)) {
        cur_type = row.slice(1, row.search(/[\s\=]/));
        if (cur_type === 'html' && !row.has('->')) {
          row = row.replace(/\=/, '= ->');
        }
      } else if (cur_type === 'html' || cur_type === 'style') {
        if (cur_type === 'html' && row.has(json_row)) {
          key = row.split(':')[0].trim().remove(/'|"/g);
          if (found_els[key] != null) {
            found_els[key] += 1;
            row = row.replace(key, "'" + key + "%" + found_els[key] + "'");
          } else {
            found_els[key] = 1;
          }
        }
        if (row.has(json_row)) {
          if ((_ref1 = rows[ind + 1]) != null ? _ref1.has(func_row) : void 0) {
            row = row.replace(':', ': do =>');
          }
        } else {
          row = row.replace(/:\s*->/, ': do =>');
        }
      }
      return new_rows.push(row);
    });
    file_str = new_rows.join('\n');
    style_regexp = /@style(.|\n)*?($|\n(?!\s))/g;
    style_str = (_ref1 = file_str.match(style_regexp)) != null ? _ref1[0] : void 0;
    if (style_str != null) {
      try {
        style_js = result_of(CS.compile(style_str, {
          bare: true
        }));
        with( Houce.ccss ){
        var style = eval(style_js);
      };

        style = result_of(style);
      } catch (err) {
        error("when parsing @style of " + tmpl_name + ".tmpl\n" + err);
        return;
      }
      ccss.shortcuts(style);
      try {
        css = ccss.compile(style);
      } catch (err) {
        error("\nERROR in compiling @style in template: " + tmpl_name + "." + file_extension + ": " + err);
        return;
      }
      if (css.length) {
        bundle.add_resource({
          type: "css",
          path: serve_path.replace('.tmpl', '.css'),
          data: css,
          where: where
        });
      }
      file_str = file_str.remove(style_regexp.addFlag('g'));
    }
    try {
      tmpl_js = CS.compile(file_str, {
        bare: true
      });
    } catch (err) {
      error("in compiling '" + source_path + "'\n" + err);
      return;
    }
    tmpl_js = "if( Meteor.is_client ){ Template." + tmpl_name + " = new function(){\n" + tmpl_js + " } }";
    return bundle.add_resource({
      type: "js",
      path: serve_path.replace('.tmpl', '.js'),
      data: tmpl_js,
      where: where
    });
  });

  Package.register_extension("plaa", function(bundle, source_path, serve_path, where) {
    return console.log("processing PLAA " + source_path.slice(18) + " for test");
  });

  Package.register_extension("ccss", function(bundle, source_path, serve_path, where) {
    var css, file_str, style, style_js;
    console.log("processing CCSS " + source_path.slice(18));
    error.bundle = bundle;
    file_str = fs.readFileSync(source_path).toString().trim();
    try {
      style_js = result_of(CS.compile(file_str, {
        bare: true
      }));
      with( Houce.ccss ){
      var style = eval(style_js);
    };

      style = result_of(style);
    } catch (err) {
      error("in parsing " + source_path + "\n" + err);
      return;
    }
    ccss.shortcuts(style);
    try {
      css = ccss.compile(style);
    } catch (err) {
      error("\nERROR in compiling @style in template: " + templ_name + "." + file_extension + ": " + err);
      return;
    }
    return bundle.add_resource({
      type: "css",
      path: serve_path.replace('.ccss', '.css'),
      data: css,
      where: where
    });
  });

  Package.register_extension("coffee", function(bundle, source_path, serve_path, where) {
    var contents;
    console.log("processing COFF " + (source_path.remove(process.env.PWD)));
    serve_path = serve_path + '.js';
    contents = fs.readFileSync(source_path);
    try {
      contents = CS.compile(contents.toString('utf8'), {
        filename: source_path
      });
    } catch (e) {
      return bundle.error(e.message);
    }
    contents = new Buffer(contents);
    return bundle.add_resource({
      type: "js",
      path: serve_path,
      data: contents,
      where: where
    });
  });

}).call(this);
