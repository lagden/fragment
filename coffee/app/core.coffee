'use strict'

define [
  'components/switch'
], (SwitchSlide) ->

  els = document.querySelectorAll '.switchSlide'
  sss = [].map.call els, (el) ->
    SwitchSlide el

  return
