// Web Speech API (speech-to-text) glue. Exposes a pollable state object so the
// Flutter app can read progress reliably (no cross-language callbacks).
(function () {
  let rec = null;
  const state = { status: 'idle', transcript: '', error: '' };
  window._fluentaiStt = state;

  window.sttStart = function (lang) {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) { state.status = 'error'; state.error = 'unsupported'; return; }
    try {
      state.status = 'listening';
      state.transcript = '';
      state.error = '';
      rec = new SR();
      rec.lang = lang || 'en-US';
      rec.interimResults = true;
      rec.continuous = false;
      rec.maxAlternatives = 1;
      rec.onresult = function (e) {
        let t = '';
        for (let i = 0; i < e.results.length; i++) t += e.results[i][0].transcript;
        state.transcript = t;
        if (e.results[e.results.length - 1].isFinal) state.status = 'final';
      };
      rec.onerror = function (e) { state.status = 'error'; state.error = (e && e.error) || 'error'; };
      rec.onend = function () { if (state.status !== 'final') state.status = state.transcript ? 'final' : 'ended'; };
      rec.start();
    } catch (err) {
      state.status = 'error';
      state.error = '' + err;
    }
  };

  window.sttStop = function () { if (rec) { try { rec.stop(); } catch (e) {} } };
  window.sttPoll = function () { return JSON.stringify(window._fluentaiStt); };
})();
