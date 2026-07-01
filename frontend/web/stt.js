// Minimal Web Speech API (speech-to-text) glue used by the Flutter app.
(function () {
  let rec = null;
  window.sttStart = function (lang, onFinal, onEnd, onError) {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) { if (onError) onError('unsupported'); if (onEnd) onEnd(); return; }
    try {
      rec = new SR();
      rec.lang = lang || 'en-US';
      rec.interimResults = false;
      rec.continuous = false;
      rec.maxAlternatives = 1;
      rec.onresult = function (e) {
        let t = '';
        for (let i = 0; i < e.results.length; i++) t += e.results[i][0].transcript;
        if (onFinal) onFinal(t);
      };
      rec.onerror = function (e) { if (onError) onError((e && e.error) || 'error'); };
      rec.onend = function () { if (onEnd) onEnd(); };
      rec.start();
    } catch (err) {
      if (onError) onError('' + err);
      if (onEnd) onEnd();
    }
  };
  window.sttStop = function () { if (rec) { try { rec.stop(); } catch (e) {} } };
})();
