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
  var Dragger, getMatrix, transform;
  transform = getStyleProperty('transform');
  getMatrix = function (el) {
    var cs, m, p, parse;
    cs = window.getComputedStyle(el, null);
    m = cs.getPropertyValue(transform);
    p = m.match(/[\-0-9]+/g);
    if (p !== null) {
      return parse = p.map(function (n) {
        return parseInt(n, 10);
      });
    } else {
      return parse = [
        0,
        0,
        0,
        0,
        0,
        0
      ];
    }
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
      console.log('dragStart');
      classie.add(this.element, 'is-dragging');
      this.pos = getMatrix(this.element);
    };
    Dragger.prototype.dragMove = function (event, pointer, moveVector) {
      var currentX, dragX;
      console.log('dragMove');
      dragX = moveVector.x + this.pos[4];
      currentX = Math.min(this.max, Math.max(dragX, this.min));
      this.element.style[transform] = 'translate3d(' + currentX + 'px, 0, 0)';
    };
    Dragger.prototype.dragEnd = function (event, pointer) {
      var endX;
      console.log('dragEnd');
      classie.remove(this.element, 'is-dragging');
      this.pos = getMatrix(this.element);
      endX = Math.round(this.pos[4] / this.max) * this.max;
      this.emitEvent('update', [endX]);
    };
    return Dragger;
  }(Unidragger);
});