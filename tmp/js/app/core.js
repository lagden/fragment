'use strict';
define(['components/switch'], function(SwitchSlide) {
  var els, frm, sss;
  els = document.querySelectorAll('.switchSlide');
  sss = [].map.call(els, function(el) {
    return SwitchSlide(el);
  });
  sss.map(function(ss) {
    return ss.ee.on('status', function(phase, value) {
      return console.log(phase, value);
    });
  });
  frm = document.querySelector('#frm');
  frm.addEventListener('reset', function() {
    var i, len, ss;
    for (i = 0, len = sss.length; i < len; i++) {
      ss = sss[i];
      ss.reset();
    }
  }, false);
  window.sss = sss;
});
