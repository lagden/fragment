'use strict'

define [
  'templates/sample'
  'draggabilly/draggabilly'
  'TweenLite'
  'Draggable'
  'CSSPlugin'
], (template, Draggabilly, TweenLite, Draggable, CSSPlugin) ->

  html = template
    widget: 'widgetSlide'
    knob: 'widgetSlide__knob'
    opts: 'widgetSlide__opt'
    optsMin: 'widgetSlide__opt--min'
    optsMax: 'widgetSlide__opt--max'
    captionMin: 'Min'
    captionMax: 'Max'

  console.debug html

  text = (node, txt) ->
    node.appendChild document.createTextNode(txt)
    return node

  container = document.querySelector '.switchSlide'
  fragment = document.createDocumentFragment()

  # Elements
  widget = document.createElement 'div'
  widget.className = 'widgetSlide'

  knob = document.createElement 'div'
  knob.className = 'widgetSlide__knob'

  optsMin = document.createElement 'div'
  optsMin.className = 'widgetSlide__opt widgetSlide__opt--min'
  spanMin = text document.createElement('span'), 'Min'

  optsMax = document.createElement 'div'
  optsMax.className = 'widgetSlide__opt widgetSlide__opt--max'
  spanMax = text document.createElement('span'), 'Max'

  # Append
  optsMin.appendChild spanMin
  optsMax.appendChild spanMax

  widget.appendChild optsMin
  widget.appendChild knob
  widget.appendChild optsMax

  fragment.appendChild widget

  container.appendChild fragment

  # Size
  knobComputedStyle = window.getComputedStyle knob
  knobMarLeft  = parseInt knobComputedStyle.marginLeft, 10
  knobMarRight = parseInt knobComputedStyle.marginRight, 10

  sMin = optsMin.getBoundingClientRect()
  sMax = optsMax.getBoundingClientRect()
  sKnob = knob.getBoundingClientRect()

  sizes =
    'sMin'   : sMin.width
    'sMax'   : sMax.width
    'knob'   : sKnob.width
    'margin' : knobMarLeft + knobMarRight
    'max'    : Math.max sMin.width, sMax.width

  optsMin.style.width   = "#{sizes.max}px"
  optsMax.style.width   = "#{sizes.max}px"
  knob.style.width      = "#{sizes.max - sizes.margin}px"
  container.style.width = "#{sizes.max * 2}px"

  console.log sizes

  # Draggabilly.prototype.positionDrag = Draggabilly.prototype.setLeftTop
  # draggie = new Draggabilly knob,
  #                           axis: 'x'
  #                           containment: container

  # draggie.on 'dragMove', (instance, event, pointer) ->
  #   console.log "#{pointer.pageX} #{instance.position.x}"
  #   return

  # draggie.on 'dragEnd', (instance, event, pointer) ->
  #   console.log pointer
  #   return

  draggie = Draggable.create knob,
    bounds: container
    edgeResistance: 0.65
    type: 'x'
    # snap:
    #   x: (endValue) ->
    #     Math.round(endValue / sizes.max) * sizes.max
    onDragEnd: () ->
      TweenLite.to knob, 0.3,
        x: Math.round(knob._gsTransform.x / sizes.max) * sizes.max
      return

  return
