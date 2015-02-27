'use strict';
define('config', function() {
  requirejs.config({
    baseUrl: '/js/lib',
    paths: {
      app: '../app',
      templates: '../templates',
      'TweenLite': './gsap/src/uncompressed/TweenLite',
      'Draggable': './gsap/src/uncompressed/utils/Draggable',
      'CSSPlugin': './gsap/src/uncompressed/plugins/CSSPlugin'
    }
  });
});
