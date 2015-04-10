'use strict';
define([
  './dragger',
  'eventEmitter/EventEmitter',
  'tap',
  'classie/classie',
  'get-style-property/get-style-property'
], function (Dragger, EventEmitter, Tap, classie, getStyleProperty) {
  var GUID, SwitchSlide, SwitchSlideException, checked, docBody, extendObject, getSizes, instances, isElement, removeAllChildren, text, transform, unchecked;
  transform = getStyleProperty('transform');
  docBody = document.querySelector('body');
  extendObject = function (a, b) {
    var prop;
    for (prop in b) {
      a[prop] = b[prop];
    }
    return a;
  };
  isElement = function (obj) {
    if (typeof HTMLElement === 'object') {
      return obj instanceof HTMLElement;
    } else {
      return obj && typeof obj === 'object' && obj.nodeType === 1 && typeof obj.nodeName === 'string';
    }
  };
  removeAllChildren = function (el) {
    var c;
    while (el.hasChildNodes()) {
      c = el.lastChild;
      if (c.hasChildNodes()) {
        el.removeChild(removeAllChildren(c));
      } else {
        el.removeChild(c);
      }
    }
    return el;
  };
  text = function (node, txt) {
    node.appendChild(document.createTextNode(txt));
    return node;
  };
  GUID = 0;
  instances = {};
  checked = function (radio) {
    radio.setAttribute('checked', '');
    radio.checked = true;
  };
  unchecked = function (radio) {
    radio.removeAttribute('checked');
    radio.checked = false;
  };
  getSizes = function (container, css) {
    var bA, bB, bKnob, clone, knob, knobComputedStyle, knobMarLeft, knobMarRight, sA, sB, sizes, widget;
    clone = container.cloneNode(true);
    clone.style.visibility = 'hidden';
    clone.style.position = 'absolute';
    docBody.appendChild(clone);
    widget = clone.querySelector('.' + css.widget);
    sA = widget.querySelector('.' + css.optA);
    sB = widget.querySelector('.' + css.optB);
    knob = widget.querySelector('.' + css.knob);
    knobComputedStyle = window.getComputedStyle(knob);
    knobMarLeft = parseInt(knobComputedStyle.marginLeft, 10);
    knobMarRight = parseInt(knobComputedStyle.marginRight, 10);
    bA = sA.getBoundingClientRect();
    bB = sB.getBoundingClientRect();
    bKnob = knob.getBoundingClientRect();
    docBody.removeChild(removeAllChildren(clone));
    return sizes = {
      'sA': parseInt(bA.width, 10),
      'sB': parseInt(bB.width, 10),
      'knob': parseInt(bKnob.width, 10),
      'margin': knobMarLeft + knobMarRight,
      'max': parseInt(Math.max(bA.width, bB.width, 10))
    };
  };
  SwitchSlideException = function () {
    function SwitchSlideException(message, name) {
      this.message = message;
      this.name = name !== null ? name : 'SwitchSlideException';
    }
    return SwitchSlideException;
  }();
  SwitchSlide = function () {
    function SwitchSlide(container, options) {
      var id, initialized, k, ref, v;
      if (false === this instanceof SwitchSlide) {
        return new SwitchSlide(container, options);
      }
      if (typeof container === 'string') {
        this.container = document.querySelector(container);
      } else {
        this.container = container;
      }
      if (isElement(this.container === false)) {
        throw new SwitchSlideException('\u2716 The container must be an HTMLElement');
      } else {
        initialized = SwitchSlide.data(this.container);
        if (initialized instanceof SwitchSlide) {
          return initialized;
        } else {
          id = ++GUID;
          this.container.GUID = id;
          instances[id] = this;
          this.options = {
            observer: null,
            error: 'widgetSlide--error',
            widget: '',
            opts: '',
            optA: '',
            optB: '',
            knob: ''
          };
          extendObject(this.options, options);
          this.css = {
            widget: 'widgetSlide',
            opts: 'widgetSlide__opt',
            optA: 'widgetSlide__opt--a',
            optB: 'widgetSlide__opt--b',
            knob: 'widgetSlide__knob'
          };
          ref = this.css;
          for (k in ref) {
            v = ref[k];
            this.options[k] = (v + ' ' + this.options[k]).trim();
          }
          this.ee = new EventEmitter();
          this.build();
        }
      }
    }
    SwitchSlide.prototype.build = function () {
      var configObserver, fragment, hasMutation, i, idx, k, label, labelOpts, len, observer, observerHandler, radio, ref, sizes, that;
      that = this;
      fragment = document.createDocumentFragment();
      this.widget = this.container.querySelector('.' + this.css.widget);
      this.widget.setAttribute('tabindex', 0);
      this.labels = this.container.getElementsByTagName('label');
      this.radios = [];
      this.taps = [];
      labelOpts = [
        this.options.optA,
        this.options.optB
      ];
      if (this.labels.length !== 2) {
        throw new SwitchSlideException('\u2716 No labels');
      } else {
        ref = this.labels;
        for (idx = i = 0, len = ref.length; i < len; idx = ++i) {
          label = ref[idx];
          classie.add(label, this.options.opts);
          classie.add(label, labelOpts[idx]);
          radio = label.nextElementSibling;
          this.radios.push(radio);
          this.taps.push(new Tap(label));
        }
      }
      this.knob = document.createElement('div');
      classie.add(this.knob, this.options.knob);
      this.knobSpan = text(document.createElement('span'), '');
      this.knob.appendChild(this.knobSpan);
      fragment.appendChild(this.knob);
      this.widget.appendChild(fragment);
      sizes = getSizes(this.container, this.css);
      this.labels[0].style.width = sizes.max + 'px';
      this.labels[1].style.width = sizes.max + 'px';
      this.knob.style.width = sizes.max - sizes.margin + 'px';
      this.container.style.width = sizes.max * 2 + 'px';
      this.labels[0].setAttribute('data-endX', 0);
      this.labels[1].setAttribute('data-endX', sizes.max);
      this.min = 0;
      this.max = sizes.max;
      this.keyCodes = {
        'space': 32,
        'left': 37,
        'right': 39
      };
      this.phases = [
        'off',
        'on'
      ];
      this.keys = {
        off: {
          label: this.labels[0],
          radio: this.radios[0],
          pos: this.min
        },
        on: {
          label: this.labels[1],
          radio: this.radios[1],
          pos: this.max
        }
      };
      observerHandler = function (radio) {
        var has, method;
        has = classie.has(radio, that.options.observer);
        method = has ? 'add' : 'remove';
        classie[method](that.widget, that.options.error);
      };
      hasMutation = 'MutationObserver' in window;
      if (hasMutation && this.options.observer) {
        observer = new MutationObserver(function (ms) {
          ms.forEach(function (m) {
            if (m.attributeName === 'class') {
              observerHandler(m.target);
            }
          });
        });
        configObserver = {
          attributes: true,
          attributeOldValue: true
        };
      }
      for (k in this.keys) {
        radio = this.keys[k].radio;
        if (observer) {
          observer.observe(radio, configObserver);
        }
        if (radio.checked) {
          this.update(this.keys[k].pos);
        }
      }
      this.listeners();
    };
    SwitchSlide.prototype.listeners = function () {
      var i, label, len, ref, that;
      that = this;
      ref = this.labels;
      for (i = 0, len = ref.length; i < len; i++) {
        label = ref[i];
        label.addEventListener('tap', this, false);
      }
      this.widget.addEventListener('keydown', this, true);
      this.dragger = new Dragger(this.knob, this.min, this.max);
      this.dragger.on('update', function (endX) {
        return that.update(endX);
      });
    };
    SwitchSlide.prototype.tapHandler = function (event) {
      var el, endX;
      event.stopPropagation();
      event.preventDefault();
      el = event.currentTarget;
      endX = parseInt(el.getAttribute('data-endX'), 10);
      this.update(endX);
    };
    SwitchSlide.prototype.onKeydownHandler = function (event) {
      var a, b;
      switch (event.keyCode) {
      case this.keyCodes.space:
        a = this.phase === this.phases[0] ? 0 : 1;
        b = a ^ 1;
        this.update(this.keys[this.phases[b]].pos);
        break;
      case this.keyCodes.right:
        this.update(this.keys.on.pos);
        break;
      case this.keyCodes.left:
        this.update(this.keys.off.pos);
      }
    };
    SwitchSlide.prototype.update = function (endX) {
      var k;
      this.knob.style[transform] = 'translate3d(' + endX + 'px, 0, 0)';
      k = endX === this.min ? 'off' : 'on';
      this.knobSpan.textContent = this.keys[k].label.textContent;
      this.status(k);
    };
    SwitchSlide.prototype.status = function (phase) {
      var k, m, params, radio;
      this.phase = null;
      this.value = null;
      for (k in this.keys) {
        radio = this.keys[k].radio;
        if (k === phase) {
          this.phase = k;
          this.value = radio.value;
          checked(radio);
        } else {
          unchecked(radio);
        }
      }
      m = this.phase === null ? 'remove' : 'add';
      classie[m](this.widget, 'has-phase');
      params = [
        this.phase,
        this.value
      ];
      this.ee.emitEvent('status', params);
    };
    SwitchSlide.prototype.setByValue = function (v) {
      var k;
      for (k in this.keys) {
        if (this.keys[k].radio.value === v) {
          this.update(this.keys[k].pos);
        }
      }
    };
    SwitchSlide.prototype.reset = function () {
      this.status('reset');
    };
    SwitchSlide.prototype.handleEvent = function (event) {
      switch (event.type) {
      case 'tap':
        this.tapHandler(event);
        break;
      case 'keydown':
        this.onKeydownHandler(event);
      }
    };
    return SwitchSlide;
  }();
  SwitchSlide.data = function (el) {
    var id;
    id = el && el.GUID;
    return id && instances[id];
  };
  return SwitchSlide;
});