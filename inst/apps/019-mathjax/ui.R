fluidPage(
  title = 'MathJax Examples',
  withMathJax(
    # Don't show "Processing math...", "Loading math...", to make timing
    # easier for testing.
    tags$script(HTML("
      MathJax.Hub.Config({
        showProcessingMessages: false,
        messageStyle: 'none'
      });
    "))
  ),
  helpText('An irrational number \\(\\sqrt{2}\\)
           and a fraction $$1-\\frac{1}{2}$$'),
  helpText('and a fact about \\(\\pi\\):
           $$\\frac2\\pi = \\frac{\\sqrt2}2 \\cdot
           \\frac{\\sqrt{2+\\sqrt2}}2 \\cdot
           \\frac{\\sqrt{2+\\sqrt{2+\\sqrt2}}}2 \\cdots$$'),
  uiOutput('ex1'),
  uiOutput('ex2'),
  uiOutput('ex3'),
  uiOutput('ex4'),
  checkboxInput('ex5_visible', 'Show Example 5', FALSE),
  uiOutput('ex5')
)
