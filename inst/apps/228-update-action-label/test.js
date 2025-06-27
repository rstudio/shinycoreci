function click(button_id) {
  return () => {
    $(`#${button_id}`).click();
  };
}

function assertWithTimeout(assertion, timeout = 1000, interval = 50) {
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

function testcase(jst, name, fns, icon, label) {
  jst.add(() => console.log(`Running test: ${name}`));
  if (Array.isArray(fns)) {
    for (const fn of fns) {
      jst.add(fn);
    }
  } else {
    jst.add(fns);
  }
  jst.add(Jster.shiny.waitUntilIdle);
  jst.add(() => assertWithTimeout(() => {

    // Wait til button is present (it's dynamic UI)
    const btn = document.getElementById("btn");
    if (!btn) { return false; }

    // Label and icon are both part of the button's inner HTML
    const html = btn.innerHTML;
    
    // Helper function to test a pattern
    function testPattern(pattern, isIcon = false) {
      if (pattern === false) {
        // false means we want to ensure the general pattern is NOT present
        if (isIcon) {
          // Test that no Bootstrap icon classes are present
          return !/bi-\w+/.test(html);
        } else {
          // Test that no label text is present (assuming labels have some text content)
          // This regex looks for any meaningful text content (not just whitespace/HTML)
          return !/[a-zA-Z0-9]/.test(html.replace(/<[^>]*>/g, '').trim());
        }
      }
      
      if (pattern instanceof RegExp) {
        return pattern.test(html);
      } else {
        return html.includes(pattern);
      }
    }
    
    const iconMatch = testPattern(icon, true);
    const labelMatch = testPattern(label, false);

    // Debugging output
    if (iconMatch === false) {
      console.log("icon pattern didn't match", iconMatch);
    }
    if (labelMatch === false) {
      console.log("label pattern didn't match", labelMatch);
    }
    
    return iconMatch && labelMatch;
  }));
}

var jst = jster();
jst.add(Jster.shiny.waitUntilIdle);

testcase(
  jst,
  "Initial state is ok",
  [],
  "bi-heart",
  "Initial label"
);

var new_label = click("new_label");
var new_icon = click("new_icon");
var new_label_icon = click("new_label_icon");

var clear_label = click("clear_label");
var clear_icon = click("clear_icon");
var clear_label_icon = click("clear_label_icon");

var as_link = click("as_link");
var initial_label = click("initial_label");
var initial_icon = click("initial_icon");

var label_prefix = "New &amp; fresh label "

testcase(
  jst,
  "Label is updated",
  new_label,
  "bi-heart",
  label_prefix + "1"
);

testcase(
  jst,
  "Label is updated 2",
  new_label,
  "bi-heart",
  label_prefix + "2"
);

testcase(
  jst,
  "Icon is updated",
  new_icon,
  "bi-star",
  label_prefix + "2"
);

testcase(
  jst,
  "Icon is updated 2",
  new_icon,
  "bi-info",
  label_prefix + "2"
);

testcase(
  jst,
  "Label and icon are updated",
  new_label_icon,
  "bi-award",
  label_prefix + "3"
);

testcase(
  jst,
  "Label is cleared",
  clear_label,
  "bi-award",
  false
);

testcase(
  jst,
  "Icon is cleared",
  clear_icon,
  false,
  false
);

testcase(
  jst,
  "Icon is added (after clearing)",
  new_icon,
  "bi-trash",
  false
);

testcase(
  jst,
  "New label and icon (after clearing)",
  new_label,
  "bi-trash",
  label_prefix + "4"
);

testcase(
  jst,
  "As link is toggled",
  as_link,
  "bi-heart",
  "Initial label"
);

testcase(
  jst,
  "Icon is updated",
  new_icon,
  "bi-search",
  "Initial label"
);

testcase(
  jst,
  "Label is updated",
  new_label,
  "bi-search",
  label_prefix + "5"
);

testcase(
  jst,
  "Label and icon are updated again",
  new_label_icon,
  "bi-files",
  label_prefix + "6"
);

testcase(
  jst,
  "Icon is cleared",
  clear_icon,
  false,
  label_prefix + "6"
);

testcase(
  jst,
  "Label is cleared",
  clear_label,
  false,
  false
);

testcase(
  jst,
  "Back to button with no initial label",
  [as_link, initial_label],
  "bi-heart",
  false
);

testcase(
  jst,
  "Update label",
  new_label,
  "bi-heart",
  label_prefix + "7"
);

testcase(
  jst,
  "Update icon",
  new_icon,
  "bi-virus",
  label_prefix + "7"
);

testcase(
  jst,
  "No initial icon",
  [initial_label, initial_icon],
  false,
  "Initial label"
);

testcase(
  jst,
  "Label is updated",
  new_label,
  false,
  label_prefix + "8"
);

testcase(
  jst,
  "Icon is updated",
  new_icon,
  "bi-check",
  label_prefix + "8"
);

testcase(
  jst,
  "Label and icon are updated again",
  new_label_icon,
  "bi-star",
  label_prefix + "9"
);

testcase(
  jst,
  "Icon is cleared",
  clear_icon,
  false,
  label_prefix + "9"
);

testcase(
  jst,
  "Label is cleared",
  clear_label,
  false,
  false
);

jst.test();
