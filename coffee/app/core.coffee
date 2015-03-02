'use strict'

define [
  'classie/classie'
  'TweenLite'
  'Draggable'
  'CSSPlugin'
], (classie, TweenLite, Draggable, CSSPlugin) ->

  # Verify
  hasTouchEvents = 'ontouchstart' of window
  hasPointerEvents = Boolean navigator.pointerEnabled or
                             navigator.msPointerEnabled
  isTouch = Boolean hasTouchEvents or
                    hasPointerEvents

  # Event
  eventType = if isTouch then 'touchend' else 'click'

  # Methods
  text = (node, txt) ->
    node.appendChild document.createTextNode(txt)
    return node

  update = (endX) ->
    k = if endX is 0 then 'off' else 'on'
    knob.textContent = keys[k].textContent
    return

  tap = (event) ->
    el = event.currentTarget
    endX = parseInt el.getAttribute('data-endX'), 10
    TweenLite.set knob, x: endX
    update endX
    return

  container = document.querySelector '.switchSlide'
  fragment = document.createDocumentFragment()

  # Elements
  widget = document.createElement 'div'
  widget.className = 'widgetSlide'

  knob = text document.createElement('div'), ''
  knob.className = 'widgetSlide__knob'

  optsA = text document.createElement('div'), 'off A'
  optsA.className = 'widgetSlide__opt widgetSlide__opt--a'

  optsB = text document.createElement('div'), 'on B'
  optsB.className = 'widgetSlide__opt widgetSlide__opt--b'

  keys =
    off: optsA
    on: optsB

  widget.appendChild optsA
  widget.appendChild knob
  widget.appendChild optsB

  fragment.appendChild widget

  container.appendChild fragment

  # Size
  knobComputedStyle = window.getComputedStyle knob
  knobMarLeft  = parseInt knobComputedStyle.marginLeft, 10
  knobMarRight = parseInt knobComputedStyle.marginRight, 10

  sA = optsA.getBoundingClientRect()
  sB = optsB.getBoundingClientRect()
  sKnob = knob.getBoundingClientRect()

  sizes =
    'sA'     : parseInt sA.width, 10
    'sB'     : parseInt sB.width, 10
    'knob'   : parseInt sKnob.width, 10
    'margin' : knobMarLeft + knobMarRight
    'max'    : parseInt Math.max sA.width, sB.width, 10

  optsA.style.width     = "#{sizes.max}px"
  optsB.style.width     = "#{sizes.max}px"
  knob.style.width      = "#{sizes.max - sizes.margin}px"
  container.style.width = "#{sizes.max * 2}px"

  optsA.setAttribute 'data-endX', 0
  optsB.setAttribute 'data-endX', sizes.max

  # Listener
  optsA.addEventListener eventType, tap, false
  optsB.addEventListener eventType, tap, false

  # Drag
  draggie = Draggable.create knob,
    bounds: container
    edgeResistance: 0.65
    type: 'x'
    lockAxis: 'x',
    force3D: true
    cursor: 'ew-resize'
    onDragStart: ->
      classie.add knob, 'is-dragging'
      return
    onDragEnd: ->
      classie.remove knob, 'is-dragging'
      endX = Math.round(knob._gsTransform.x / sizes.max) * sizes.max
      TweenLite.set knob, x: endX
      update endX
      return

  return
