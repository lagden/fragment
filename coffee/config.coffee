'use strict'

define 'config', ->
  requirejs.config
    baseUrl: '/js/lib'
    paths:
      app: '../app'
      templates: '../templates'
      components: '../components'
      TweenLite: './gsap/src/uncompressed/TweenLite',
      Draggable: './gsap/src/uncompressed/utils/Draggable',
      CSSPlugin: './gsap/src/uncompressed/plugins/CSSPlugin',

  return
