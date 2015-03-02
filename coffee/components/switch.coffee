'use strict'

define [
  'classie/classie'
  'eventEmitter/EventEmitter'
  'TweenLite'
  'Draggable'
  'CSSPlugin'
], (classie, EventEmitter, TweenLite, Draggable, CSSPlugin) ->

  # Verify
  hasTouchEvents = 'ontouchstart' of window
  hasPointerEvents = Boolean navigator.pointerEnabled or
                             navigator.msPointerEnabled
  isTouch = Boolean hasTouchEvents or
                    hasPointerEvents

  # Event
  eventType = if isTouch then 'touchend' else 'click'

  # Extend object
  extend = (a, b) ->
    a[prop] = b[prop] for prop of b
    return a

  # Verify if object is an HTMLElement
  isElement = (obj) ->
    if typeof HTMLElement is 'object'
      return obj instanceof HTMLElement
    else
      return obj and
             typeof obj is 'object' and
             obj.nodeType is 1 and
             typeof obj.nodeName is 'string'

  # Append text node inside the element
  text = (node, txt) ->
    node.appendChild document.createTextNode(txt)
    return node

  # Globally unique identifiers
  GUID = 0

  # Internal store of all SwitchSlide intances
  instances = {}

  # Exception
  class SwitchSlideException
    constructor: (@message, @name='SwitchSlideException') ->

  # Class
  class SwitchSlide

    constructor: (container, options) ->

      # Self instance
      if false is (@ instanceof SwitchSlide)
        return new SwitchSlide container, options

      # Get container
      if typeof container == 'string'
        @container = document.querySelector container
      else
        @container = container

      # Container exception
      if isElement @container is false
        throw new SwitchSlideException '✖ Container must be an HTMLElement'
      else
        # Check if component was initialized
        initialized = SwitchSlide.data @container
        if initialized instanceof SwitchSlide
          return initialized
        else
          id = ++GUID
          @container.GUID = id
          instances[id] = @

          # Options
          @options =
            widget : ''
            opts   : ''
            optMin : ''
            optMax : ''
            knob   : ''

          extend @options, options

          @css =
            initialize : 'switchSlide--initialized'
            widget     : 'widgetSlide'
            opts       : 'widgetSlide__opt'
            knob       : 'widgetSlide__knob'

          for k, v of @css
            @options[k] = "#{v} #{@options[k]}".trim()

          @ee = new EventEmitter()

          @build()

    build: ->
      fragment = document.createDocumentFragment()
      @widget = @container.querySelector ".#{@css.widget}"

      @labels = @container.getElementsByTagName 'label'
      @radios = []

      # Elements
      if @labels.length != 2
        throw new SwitchSlideException '✖ No labels'
      else
        for label in @labels
          classie.add label, @options.opts
          radio = label.nextElementSibling
          @radios.push radio

      @keys =
        off:
          label: @labels[0]
          radio: @radios[0]
        on :
          label: @labels[1]
          radio: @radios[1]

      @knob = text document.createElement('div'), ''
      classie.add @knob, @options.knob

      fragment.appendChild @knob
      @widget.appendChild fragment

      # Size
      knobComputedStyle = window.getComputedStyle @knob
      knobMarLeft  = parseInt knobComputedStyle.marginLeft, 10
      knobMarRight = parseInt knobComputedStyle.marginRight, 10

      sA = @labels[0].getBoundingClientRect()
      sB = @labels[1].getBoundingClientRect()
      sKnob = @knob.getBoundingClientRect()

      sizes =
        'sA'     : parseInt sA.width, 10
        'sB'     : parseInt sB.width, 10
        'knob'   : parseInt sKnob.width, 10
        'margin' : knobMarLeft + knobMarRight
        'max'    : parseInt Math.max sA.width, sB.width, 10

      @labels[0].style.width = "#{sizes.max}px"
      @labels[1].style.width = "#{sizes.max}px"
      @knob.style.width      = "#{sizes.max - sizes.margin}px"
      @container.style.width = "#{sizes.max * 2}px"

      @labels[0].setAttribute 'data-endX', 0
      @labels[1].setAttribute 'data-endX', sizes.max

      @max = sizes.max
      @events()

      return

    events: ->

      tap = (event) =>
        # event.stopPropagation()
        el = event.currentTarget
        endX = parseInt el.getAttribute('data-endX'), 10
        TweenLite.set @knob, x: endX
        @update endX, true
        return

      # Listener
      @labels[0].addEventListener eventType, tap, false
      @labels[1].addEventListener eventType, tap, false

      onDragStartHandler = () =>
        classie.add @knob, 'is-dragging'
        return

      onDragEndHandler = () =>
        classie.remove @knob, 'is-dragging'
        endX = Math.round(@knob._gsTransform.x / @max) * @max
        TweenLite.set @knob, x: endX
        @update endX
        return

      # Drag
      draggie = Draggable.create @knob,
        bounds: @container
        edgeResistance: 0.65
        type: 'x'
        lockAxis: 'x',
        force3D: true
        cursor: 'ew-resize'
        onDragStart: onDragStartHandler
        onDragEnd: onDragEndHandler

      return

    update: (endX, tap) ->
      tap = tap || false
      k = if endX is 0 then 'off' else 'on'
      @knob.textContent = @keys[k].label.textContent

      # @keys[k].label[eventType]() if tap is false

      @status()
      return

    status: ->
      @phase = null
      @value = null
      cc = 0
      console.log @keys
      for phase of @keys
        radio = @keys[phase].radio
        if radio.checked
          @phase = phase
          @value = radio.value

      m = if @phase is null then 'remove' else 'add'
      classie[m] @widget, 'has-phase'

      params = [
        'instance': @
        'phase': @phase
        'value': @value
      ]

      console.trace()
      console.table params

      @ee.emitEvent 'status', params

      return

  SwitchSlide.data = (el) ->
    id = el and el.GUID
    return id and instances[id]

  return SwitchSlide
