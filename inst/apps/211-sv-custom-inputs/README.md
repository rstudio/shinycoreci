## Custom inputs

In this example, the picture-taking control is a custom input control. shinyvalidate lets custom input controls decide where and how to display their input validation feedback.

**Note: As of this writing, this app doesn't work in RStudio; view it in an external browser like Chrome or Firefox instead.**

Try pressing the Submit button without taking a picture first; notice that the validation feedback message appears within the input control. This is because the [custom input binding](https://shiny.rstudio.com/articles/building-inputs.html) code for this control contains `setInvalid()` and `clearInvalid()` methods.

(If you'd like a packaged camera input widget for your actual Shiny app, consider the [`shinyviewr` function from the `shinysense` package](https://livefreeordichotomize.com/2018/07/22/shinyviewr-camera-input-for-shiny/).)

This is a slimmed down version of the [actual app](https://github.com/rstudio/shiny-examples/tree/2e8eb4870d4f1e0d84fca97a76c80776ddd71928/185-sv-custom-inputs) so that testing is less complicated.

