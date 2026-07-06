// Records the microphone with MediaRecorder (reliable on iOS Safari + Android + desktop),
// returns the recorded audio as base64. The server decodes it (ffmpeg) to PCM for Azure STT.
// The old WebAudio ScriptProcessor approach recorded silence on iOS — this replaces it.
(function () {
  let mediaRecorder, chunks = [], stream, err = '', mimeType = '';

  function pickMime() {
    var cands = ['audio/mp4', 'audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus', 'audio/ogg'];
    if (typeof MediaRecorder === 'undefined' || !MediaRecorder.isTypeSupported) return '';
    for (var i = 0; i < cands.length; i++) {
      if (MediaRecorder.isTypeSupported(cands[i])) return cands[i];
    }
    return '';
  }

  window.recStart = function () {
    err = '';
    chunks = [];
    if (typeof MediaRecorder === 'undefined') {
      err = 'NoMediaRecorder';
      return Promise.resolve(false);
    }
    return navigator.mediaDevices.getUserMedia({ audio: true }).then(function (s) {
      stream = s;
      mimeType = pickMime();
      try {
        mediaRecorder = mimeType ? new MediaRecorder(stream, { mimeType: mimeType }) : new MediaRecorder(stream);
      } catch (e) {
        mediaRecorder = new MediaRecorder(stream);
        mimeType = mediaRecorder.mimeType || '';
      }
      mediaRecorder.ondataavailable = function (e) {
        if (e.data && e.data.size > 0) chunks.push(e.data);
      };
      mediaRecorder.start();
      return true;
    }).catch(function (e) {
      err = '' + ((e && e.name) || e);
      return false;
    });
  };

  window.recError = function () { return err; };
  window.recMime = function () { return mimeType || (mediaRecorder && mediaRecorder.mimeType) || ''; };

  // Async: waits for the recorder to flush, then resolves base64 of the recorded blob.
  window.recStop = function () {
    return new Promise(function (resolve) {
      if (!mediaRecorder) { resolve(''); return; }
      mediaRecorder.onstop = function () {
        try { if (stream) stream.getTracks().forEach(function (t) { t.stop(); }); } catch (e) {}
        var type = window.recMime() || 'audio/mp4';
        var blob = new Blob(chunks, { type: type });
        if (!blob.size) { resolve(''); return; }
        var reader = new FileReader();
        reader.onloadend = function () {
          var s = '' + reader.result;         // "data:<type>;base64,XXXX"
          var i = s.indexOf(',');
          resolve(i >= 0 ? s.substring(i + 1) : '');
        };
        reader.onerror = function () { resolve(''); };
        reader.readAsDataURL(blob);
      };
      try { mediaRecorder.requestData(); } catch (e) {}
      try { mediaRecorder.stop(); } catch (e) { resolve(''); }
    });
  };
})();
