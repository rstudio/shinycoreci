js_sidebar_transition_complete <- function(id) {
  sprintf(
    "!document.getElementById('%s').parentElement.classList.contains('transitioning');",
    id
  )
}

js_sidebar_state <- function(id) {
  sprintf(
    "(function() {
      return {
      layout_classes: Array.from(document.getElementById('%s').closest('.bslib-sidebar-layout').classList),
      content_display: window.getComputedStyle(document.querySelector('#%s .sidebar-content')).getPropertyValue('display'),
      sidebar_hidden: document.getElementById('%s').hidden
    }})();",
    id, id, id
  )
}

js_element_width <- function(selector) {
  sprintf(
    "document.querySelector('%s').getBoundingClientRect().width;",
    selector
  )
}
