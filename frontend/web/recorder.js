// Records microphone audio as 16 kHz mono 16-bit PCM (base64) for server-side (Azure) STT.
// Works reliably on iOS/Safari + Android/Chrome (no flaky Web Speech dictation UI).
(function () {
  let audioCtx, source, processor, muteGain, stream, chunks = [], recording = false, err = '';

  window.recStart = function () {
    err = '';
    chunks = [];
    recording = false;
    return navigator.mediaDevices.getUserMedia({ audio: true }).then(function (s) {
      stream = s;
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      if (audioCtx.resume) audioCtx.resume();
      source = audioCtx.createMediaStreamSource(stream);
      processor = audioCtx.createScriptProcessor(4096, 1, 1);
      processor.onaudioprocess = function (e) {
        if (!recording) return;
        chunks.push(new Float32Array(e.inputBuffer.getChannelData(0)));
      };
      muteGain = audioCtx.createGain();
      muteGain.gain.value = 0; // avoid echoing the mic to the speakers
      source.connect(processor);
      processor.connect(muteGain);
      muteGain.connect(audioCtx.destination);
      recording = true;
      return true;
    }).catch(function (e) {
      err = '' + ((e && e.name) || e);
      return false;
    });
  };

  window.recError = function () { return err; };

  window.recStop = function () {
    recording = false;
    try { if (processor) processor.disconnect(); if (source) source.disconnect(); if (muteGain) muteGain.disconnect(); } catch (e) {}
    if (stream) stream.getTracks().forEach(function (t) { t.stop(); });
    const inRate = audioCtx ? audioCtx.sampleRate : 44100;
    let len = 0;
    chunks.forEach(function (c) { len += c.length; });
    const flat = new Float32Array(len);
    let off = 0;
    chunks.forEach(function (c) { flat.set(c, off); off += c.length; });
    const pcm16 = downsample(flat, inRate, 16000);
    if (audioCtx) { try { audioCtx.close(); } catch (e) {} }
    const bytes = new Uint8Array(pcm16.buffer);
    let bin = '';
    const chunk = 0x8000;
    for (let i = 0; i < bytes.length; i += chunk) {
      bin += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
    }
    return btoa(bin);
  };

  function downsample(input, inRate, outRate) {
    let data = input;
    if (inRate !== outRate) {
      const ratio = inRate / outRate;
      const newLen = Math.floor(input.length / ratio);
      const out = new Float32Array(newLen);
      for (let i = 0; i < newLen; i++) out[i] = input[Math.floor(i * ratio)];
      data = out;
    }
    const int16 = new Int16Array(data.length);
    for (let i = 0; i < data.length; i++) {
      const s = Math.max(-1, Math.min(1, data[i]));
      int16[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
    }
    return int16;
  }
})();
