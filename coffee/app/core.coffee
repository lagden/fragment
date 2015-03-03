'use strict'

define [
  'components/switch'
], (SwitchSlide) ->

  els = document.querySelectorAll '.switchSlide'
  sss = [].map.call els, (el) ->
    SwitchSlide el

  sss.map (ss) ->
    ss.ee.on 'status', (phase, value) ->
      console.log phase, value

  frm = document.querySelector '#frm'
  frm.addEventListener 'reset', () ->
    ss.reset() for ss in sss
    return
  , false

  setTimeout ->
    sss[2].container.parentNode.className = 'pad-t-10 pad-b-10'
    return
  , 2000

  window.sss = sss

  return
