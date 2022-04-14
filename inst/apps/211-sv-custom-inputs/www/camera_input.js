if (window.Shiny) {
  var cameraInputBinding = new Shiny.InputBinding();
  $.extend(cameraInputBinding, {
    find: function(scope) {
      return $(scope).find(".shiny-camera-input");
    },
    initialize: function(el) {
      const $el = $(el);
      // new ShinyCameraInput(
      //   el,
      //   $el.children("video")[0],
      //   $el.children("canvas")[0],
      //   $el.find(">output>img")[0],
      //   $el.children("button.take")[0],
      //   $el.children("button.retake")[0]
      // );
    },
    getType: function() {
      return "camera-datauri";
    },
    getValue: function(el) {
      if (el.classList.contains("shot")) {
        const img = el.querySelector("output img");
        if (img) {
          return img.src;
        }
      }
      return null;
    },
    setValue: function(el, value) {

    },
    subscribe: function(el, callback) {
      $(el).on("change.cameraInputBinding", function(e) {
        callback();
      });
    },
    unsubscribe: function(el) {
      $(el).off(".cameraInputBinding");
    },

    // The following two methods, setInvalid and clearInvalid, will be called
    // whenever this input fails or passes (respectively) validation.
    setInvalid: function(el, data) {
      el.classList.add("invalid");
      el.querySelector(".feedback-message").innerText = data.message;
    },
    clearInvalid: function(el) {
      el.classList.remove("invalid");
      el.querySelector(".feedback-message").innerText = "";
    }
  });
  Shiny.inputBindings.register(cameraInputBinding);
}
