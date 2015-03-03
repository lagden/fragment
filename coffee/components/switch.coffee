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

  # Radio checked
  checked = (radio) ->
    radio.setAttribute 'checked', ''
    radio.checked = true
    return

  # Radio unchecked
  unchecked = (radio) ->
    radio.removeAttribute 'checked'
    radio.checked = false
    return

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
        throw new SwitchSlideException '✖ The container must be an HTMLElement'
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
            observer : null
            error    : ''
            widget   : ''
            opts     : ''
            optMin   : ''
            optMax   : ''
            knob     : ''

          extend @options, options

          @css =
            error  : 'widgetSlide--error'
            widget : 'widgetSlide'
            opts   : 'widgetSlide__opt'
            knob   : 'widgetSlide__knob'

          for k, v of @css
            @options[k] = "#{v} #{@options[k]}".trim()

          @ee = new EventEmitter()

          @build()

    build: ->
      # Elements
      fragment = document.createDocumentFragment()
      @widget = @container.querySelector ".#{@css.widget}"
      @widget.setAttribute 'tabindex', 0

      @labels = @container.getElementsByTagName 'label'
      @radios = []

      if @labels.length != 2
        throw new SwitchSlideException '✖ No labels'
      else
        for label in @labels
          classie.add label, @options.opts
          radio = label.nextElementSibling
          @radios.push radio

      @knob = document.createElement('div')
      classie.add @knob, @options.knob

      @knobSpan = text document.createElement('span'), ''

      @knob.appendChild @knobSpan
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

      @min = 0
      @max = sizes.max

      # Preparing
      @keyCodes =
        'space' : 32
        'left'  : 37
        'right' : 39

      @phases = ['off', 'on']

      @keys =
        off:
          label: @labels[0]
          radio: @radios[0]
          pos  : @min
        on :
          label: @labels[1]
          radio: @radios[1]
          pos  : @max

      # Observer
      observerHandler = (radio) =>
        has = classie.has radio, @options.observer
        method = if has then 'add' else 'remove'
        classie[method] @widget, @options.error
        return

      hasMutation = `'MutationObserver' in window`
      if hasMutation and @options.observer
        observer = new MutationObserver (ms) ->
          ms.forEach (m) ->
            observerHandler m.target if m.attributeName == 'class'
            return
          return

        configObserver =
          attributes: true
          attributeOldValue: true

      # Initialize
      for k of @keys
        radio = @keys[k].radio
        observer.observe radio, configObserver if observer
        if radio.checked
          @update @keys[k].pos

      @events()
      return

    events: ->
      # Handlers
      tapHandler = (event) =>
        event.stopPropagation()
        event.preventDefault()
        el = event.currentTarget
        endX = parseInt el.getAttribute('data-endX'), 10
        @update endX
        return

      onKeydownHandler = (event) =>
        switch event.keyCode
          when @keyCodes.space
            a = if @phase == @phases[0] then 0 else 1
            b = a ^ 1
            @update @keys[@phases[b]].pos
          when @keyCodes.right
            @update @keys['on'].pos
          when @keyCodes.left
            @update @keys['off'].pos
        return

      onDragStartHandler = () =>
        classie.add @knob, 'is-dragging'
        return

      onDragEndHandler = () =>
        classie.remove @knob, 'is-dragging'
        endX = Math.round(@knob._gsTransform.x / @max) * @max
        @update endX
        return

      # Listener
      @labels[0].addEventListener eventType, tapHandler, false
      @labels[1].addEventListener eventType, tapHandler, false
      @widget.addEventListener 'keydown', onKeydownHandler, true

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

    update: (endX) ->
      TweenLite.set @knob, x: endX
      k = if endX == @min then 'off' else 'on'
      @knobSpan.textContent = @keys[k].label.textContent
      @status k
      return

    status: (phase) ->
      @phase = null
      @value = null

      for k of @keys
        radio = @keys[k].radio
        if k == phase
          @phase = k
          @value = radio.value
          checked radio
        else
          unchecked radio

      m = if @phase is null then 'remove' else 'add'
      classie[m] @widget, 'has-phase'

      params = [
        @phase
        @value
      ]

      @ee.emitEvent 'status', params
      return

    setByValue: (v) ->
      @update @keys[k].pos for k of @keys when @keys[k].radio.value == v
      return

    reset: ->
      @status 'reset'
      return

  SwitchSlide.data = (el) ->
    id = el and el.GUID
    return id and instances[id]

  return SwitchSlide
