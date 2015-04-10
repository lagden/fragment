'use strict'

define [
  'unidragger/unidragger'
  'classie/classie'
  'get-style-property/get-style-property'
], (
  Unidragger,
  classie,
  getStyleProperty
) ->

  transform = getStyleProperty 'transform'

  getMatrix = (el) ->
    cs = window.getComputedStyle el, null
    m = cs.getPropertyValue transform

    p = m.match /[\-0-9]+/g
    if p != null
      parse = p.map (n) ->
        parseInt n, 10
    else
      parse = [0, 0, 0, 0, 0, 0]

  class Dragger extends Unidragger
    constructor: (@element, @min, @max) ->
      @handles = [@element]
      @bindHandles()

    dragStart: (event, pointer) ->
      console.log 'dragStart'
      classie.add @element, 'is-dragging'
      @pos = getMatrix @element
      return

    dragMove: (event, pointer, moveVector) ->
      console.log 'dragMove'
      dragX = moveVector.x + @pos[4]
      currentX = Math.min @max, Math.max dragX, @min
      @element.style[transform] = "translate3d(#{currentX}px, 0, 0)"
      return

    dragEnd: (event, pointer) ->
      console.log 'dragEnd'
      classie.remove @element, 'is-dragging'
      @pos = getMatrix @element
      endX = Math.round(@pos[4] / @max) * @max
      @emitEvent 'update', [endX]
      return
