function click(button_id) {
  return () => {
    $(`#${button_id}`).click();
  };
}

recalc = click("calc2");
progress = click("calc2p");
error = click("calc2e");
abort = click("calc2a");
cancel = click("calc2c");

function recalculating(id = "plot2") {
  return document.getElementById(id).classList.contains("recalculating");
}

function assertWithTimeout(assertion, timeout = 5000, interval = 50) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    function attempt() {
      try {
        Jster.assert.isTrue(assertion());
        resolve();
      } catch (e) {
        if (Date.now() - start > timeout) {
          reject(e);
        } else {
          setTimeout(attempt, interval);
        }
      }
    }
    attempt();
  });
}

function testcase(jst, name, fns, selector) {
  const plot2 = document.getElementById("plot2");

  jst.add(() => console.log(`Running test: ${name}`));
  if (Array.isArray(fns)) {
    for (const fn of fns) {
      jst.add(fn);
    }
  } else {
    jst.add(fns);
  }
  jst.add(Jster.shiny.waitUntilIdle);
  jst.add(() => assertWithTimeout(() => plot2.matches(selector)));
}

var jst = jster();
jst.add(Jster.shiny.waitUntilIdle);

jst.add(click("calc1"));
testcase(jst, "Recalculation is persistent", progress, ".recalculating");
jst.add(() => Jster.assert.isTrue(!recalculating("plot1")));

testcase(
  jst,
  "Value stops recalculation",
  [progress, recalc],
  ":not(.recalculating)"
);

testcase(
  jst,
  "Error stops recalculation",
  [progress, error],
  ":not(.recalculating)"
);

testcase(
  jst,
  "Abort stops recalculation",
  [progress, abort],
  ":not(.recalculating)"
);

testcase(
  jst,
  "Can stack recalculation",
  [recalc, progress, (done) => setTimeout(done, 100), progress],
  ".recalculating"
);

const oldValue = document.querySelector("#plot1").innerHTML;
testcase(
  jst,
  "plot1 isn't blocked by plot2; plot2 doesn't stop recalculating because of plot1",
  [progress, click("calc1")],
  ".recalculating"
);
jst.add(() =>
  Jster.assert.isTrue(document.querySelector("#plot1").innerHTML !== oldValue)
);
jst.test();
