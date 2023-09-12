window.RevealNoshiftkeys = function () {
  return {
    id: "RevealNoshiftkeys",
    init: function (deck) {
      deck.configure({
        keyboard: {
          37: (e) => {
            if (!e.shiftKey) {
              deck.prev();
            }
          },
          39: (e) => {
            if (!e.shiftKey) {
              deck.next();
            }
          },
        },
      });
    },
  };
};
