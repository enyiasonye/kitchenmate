// PROTOTYPE — throwaway. Safari runs this in the page before the extension opens.
// Tests ADR 4's "Safari shares include the rendered page DOM".
var Preprocess = function () {};

Preprocess.prototype = {
  run: function (args) {
    var ld = Array.prototype.map.call(
      document.querySelectorAll('script[type="application/ld+json"]'),
      function (s) { return s.textContent; }
    );
    var og = {};
    document.querySelectorAll('meta[property^="og:"]').forEach(function (m) {
      og[m.getAttribute("property")] = m.getAttribute("content");
    });
    args.completionFunction({
      url: document.URL,
      title: document.title,
      jsonLdCount: ld.length,
      jsonLdHasRecipe: ld.some(function (t) { return /"@type"\s*:\s*(\[[^\]]*)?"Recipe"/.test(t); }),
      openGraph: JSON.stringify(og),
      selection: String(window.getSelection()),
      html: document.documentElement.outerHTML
    });
  },
  finalize: function (args) {}
};

var ExtensionPreprocessingJS = new Preprocess();
