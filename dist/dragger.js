'use strict';
var extend = function (child, parent) {
    for (var key in parent) {
      if (hasProp.call(parent, key)) {
        child[key] = parent[key];
      }
    }
    function ctor() {
      this.constructor = child;
    }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
  }, hasProp = {}.hasOwnProperty;
define([
  'unidragger/unidragger',
  'classie/classie',
  'get-style-property/get-style-property'
], function (Unidragger, classie, getStyleProperty) {
  var Dragger, getMatrix, prefixes, transform;
  transform = getStyleProperty('transform');
  prefixes = [
    '',
    '-moz-',
    '-ms-',
    '-o-',
    '-webkit-'
  ];
  getMatrix = function (el) {
    var cs, i, len, m, p, parse, prefix;
    cs = window.getComputedStyle(el, null);
    for (i = 0, len = prefixes.length; i < len; i++) {
      prefix = prefixes[i];
      m = cs.getPropertyValue(prefix + 'transform');
      if (m !== null) {
        break;
      }
    }
    parse = [
      0,
      0,
      0,
      0,
      0,
      0
    ];
    if (m) {
      p = m.match(/[\-0-9]+/g);
      if (p !== null) {
        parse = p.map(function (n) {
          return parseInt(n, 10);
        });
      }
    }
    return parse;
  };
  return Dragger = function (superClass) {
    extend(Dragger, superClass);
    function Dragger(element, min, max) {
      this.element = element;
      this.min = min;
      this.max = max;
      this.handles = [this.element];
      this.bindHandles();
    }
    Dragger.prototype.dragStart = function (event, pointer) {
      classie.add(this.element, 'is-dragging');
      this.pos = getMatrix(this.element);
    };
    Dragger.prototype.dragMove = function (event, pointer, moveVector) {
      var currentX, dragX;
      dragX = moveVector.x + this.pos[4];
      currentX = Math.min(this.max, Math.max(dragX, this.min));
      this.element.style[transform] = 'translate3d(' + currentX + 'px, 0, 0)';
    };
    Dragger.prototype.dragEnd = function (event, pointer) {
      var endX;
      classie.remove(this.element, 'is-dragging');
      this.pos = getMatrix(this.element);
      endX = Math.round(this.pos[4] / this.max) * this.max;
      this.emitEvent('update', [endX]);
    };
    return Dragger;
  }(Unidragger);
});