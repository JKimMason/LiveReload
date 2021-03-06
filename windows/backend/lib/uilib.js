// Generated by IcedCoffeeScript 1.8.0-d
(function() {
  var EventEmitter, UIConnector, debug, domain, merge,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  debug = require('debug')('livereload:uilib');

  domain = require('domain');

  EventEmitter = require('events').EventEmitter;

  merge = function(dst, src) {
    var key, oldValue, value;
    for (key in src) {
      if (!__hasProp.call(src, key)) continue;
      value = src[key];
      if ((key.match(/^#/)) && dst.hasOwnProperty(key) && (value != null) && ((oldValue = dst[key]) != null) && (typeof value === 'object') && (typeof oldValue === 'object')) {
        merge(oldValue, value);
      } else {
        dst[key] = value;
      }
    }
    return dst;
  };

  module.exports = UIConnector = (function(_super) {
    __extends(UIConnector, _super);

    function UIConnector(root, options) {
      var _ref;
      this.root = root;
      if (options == null) {
        options = {};
      }
      this._delay = (_ref = options.delay) != null ? _ref : 20;
      this._domain = domain.create();
      this._domain.add(this);
      this.root.on('update', this._mergeUpdate.bind(this));
      this._nextUpdatePayload = {};
      this._nextUpdateScheduled = false;
    }

    UIConnector.prototype._mergeUpdate = function(payload, callback) {
      if (callback) {
        return this.emit('update', payload, callback);
      } else {
        merge(this._nextUpdatePayload, payload);
        return this._scheduleUpdate();
      }
    };

    UIConnector.prototype._scheduleUpdate = function() {
      var func, timer;
      if (this._nextUpdateScheduled) {
        return;
      }
      this._nextUpdateScheduled = true;
      func = this._sendUpdate.bind(this);
      if (this._delay === 0) {
        timer = process.nextTick(func);
      } else {
        timer = setTimeout(func, this._delay);
      }
      return this._domain.add(timer);
    };

    UIConnector.prototype._sendUpdate = function() {
      var payload;
      payload = this._nextUpdatePayload;
      this._nextUpdatePayload = {};
      this._nextUpdateScheduled = false;
      return this.emit('update', payload);
    };

    return UIConnector;

  })(EventEmitter);

}).call(this);
