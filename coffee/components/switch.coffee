'use strict'

define [
  './dragger'
  'eventEmitter/EventEmitter'
  'classie/classie'
  'get-style-property/get-style-property'
], (
  Dragger,
  EventEmitter,
  classie,
  getStyleProperty
) ->

  transform = getStyleProperty 'transform'

  # Body
  docBody = document.body || document.querySelector 'body'

  # Extend object
  extendObject = (a, b) ->
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

  # Remove all children
  removeAllChildren = (el) ->
    while el.hasChildNodes()
      c = el.lastChild
      if c.hasChildNodes()
        el.removeChild removeAllChildren(c)
      else
        el.removeChild c
    return el

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

  getSizes = (container, css) ->
    clone = container.cloneNode true
    clone.style.visibility = 'hidden'
    clone.style.position   = 'absolute'

    docBody.appendChild clone

    widget = clone.querySelector ".#{css.widget}"
    sA     = widget.querySelector ".#{css.optA}"
    sB     = widget.querySelector ".#{css.optB}"
    knob   = widget.querySelector ".#{css.knob}"

    knobComputedStyle = window.getComputedStyle knob
    knobMarLeft  = parseInt knobComputedStyle.marginLeft, 10
    knobMarRight = parseInt knobComputedStyle.marginRight, 10

    bA = sA.getBoundingClientRect()
    bB = sB.getBoundingClientRect()
    bKnob = knob.getBoundingClientRect()

    # Remove
    docBody.removeChild removeAllChildren(clone)

    sizes =
      'sA'     : parseInt bA.width, 10
      'sB'     : parseInt bB.width, 10
      'knob'   : parseInt bKnob.width, 10
      'margin' : knobMarLeft + knobMarRight
      'max'    : parseInt Math.max bA.width, bB.width, 10

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
            drag     : true
            observer : null
            error    : 'widgetSlide--error'
            widget   : ''
            opts     : ''
            optA     : ''
            optB     : ''
            knob     : ''

          extendObject @options, options

          @css =
            widget : 'widgetSlide'
            opts   : 'widgetSlide__opt'
            optA   : 'widgetSlide__opt--a'
            optB   : 'widgetSlide__opt--b'
            knob   : 'widgetSlide__knob'

          for k, v of @css
            @options[k] = "#{v} #{@options[k]}".trim()

          @ee = new EventEmitter()

          @build()

    build: ->
      that = @

      # Elements
      fragment = document.createDocumentFragment()
      @widget = @container.querySelector ".#{@css.widget}"
      @widget.setAttribute 'tabindex', 0

      @labels = @container.getElementsByTagName 'label'
      @radios = []

      labelOpts = [
        @options.optA
        @options.optB
      ]

      if @labels.length != 2
        throw new SwitchSlideException '✖ No labels'
      else
        for label, idx in @labels
          classie.add label, @options.opts
          classie.add label, labelOpts[idx]
          radio = label.nextElementSibling
          @radios.push radio

      @knob = document.createElement('div')
      classie.add @knob, @options.knob

      @knobSpan = text document.createElement('span'), ''

      @knob.appendChild @knobSpan
      fragment.appendChild @knob
      @widget.appendChild fragment

      # Size
      sizes = getSizes @container, @css

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
        on:
          label: @labels[1]
          radio: @radios[1]
          pos  : @max

      # Observer
      observerHandler = (radio) ->
        has = classie.has radio, that.options.observer
        method = if has then 'add' else 'remove'
        classie[method] that.widget, that.options.error
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

      @listeners()
      return

    listeners: ->
      that = @
      label.addEventListener 'click', @, false for label in @labels
      @widget.addEventListener 'keydown', @, true

      if @options.drag
        @dragger = new Dragger @knob, @min, @max
        @dragger.on 'update', (endX) ->
          that.update endX
      return

    tapHandler: (event) ->
      event.stopPropagation()
      event.preventDefault()
      el = event.currentTarget
      endX = parseInt el.getAttribute('data-endX'), 10
      @update endX
      return

    onKeydownHandler: (event) ->
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

    update: (endX) ->
      @knob.style[transform] = "translate3d(#{endX}px, 0, 0)"
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

    destroy: ->
      label.removeEventListener 'click', @, false for label in @labels
      @widget.removeEventListener 'keydown', @, true
      @knob = removeAllChildren @knob
      @widget.removeChild @knob
      return

    handleEvent: (event) ->
      switch event.type
        when 'click' then @tapHandler event
        when 'keydown' then @onKeydownHandler event
      return

  SwitchSlide.data = (el) ->
    id = el and el.GUID
    return id and instances[id]

  return SwitchSlide
