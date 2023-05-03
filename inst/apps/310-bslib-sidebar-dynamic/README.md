## 310-bslib-sidebar-dynamic

Two test suites around the bslib sidebar implementation:

1. `310-bslib-sidebar-dynamic` tests the sidebar when added to the page dynamically. The sidebar dependencies are not present on page load but are included when the sidebars are added via `insertUI()`. We test general function and form of the sidebar, in particular around initialization state and the collapse toggle event handlers that would not work correctly if the sidebar dependencies did not include special post-page-load initialization methods.

2. `310-bslib-sidebar-toggle-methods` tests the tab focus order of nested sidebars and all of the related sidebar toggling methods, including server-side `sidebar_toggle()`.

