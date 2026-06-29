(function () {
  var btns = document.querySelectorAll(".cat-btn");
  var arts = document.querySelectorAll("article[data-cats]");
  var activo = null;

  btns.forEach(function (b) {
    b.addEventListener("click", function () {
      var cat = this.getAttribute("data-cat");

      if (this.classList.contains("activo")) {
        this.classList.remove("activo");
        activo = null;
        document.querySelector('.cat-btn[data-cat="*"]').classList.add("activo");
      } else {
        btns.forEach(function (x) { x.classList.remove("activo"); });
        this.classList.add("activo");
        activo = cat;
      }

      arts.forEach(function (a) {
        if (!activo || activo === "*") {
          a.style.display = "";
        } else {
          var cats = (a.getAttribute("data-cats") || "").split(" ");
          a.style.display = cats.indexOf(activo) !== -1 ? "" : "none";
        }
      });
    });
  });
})();
