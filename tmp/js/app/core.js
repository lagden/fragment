'use strict';
define(['components/switch'], function(SwitchSlide) {
  var els, sss;
  els = document.querySelectorAll('.switchSlide');
  sss = [].map.call(els, function(el) {
    return SwitchSlide(el);
  });
});
