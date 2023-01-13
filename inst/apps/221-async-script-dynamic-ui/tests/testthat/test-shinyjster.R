# R<=3.5 doesn't support removeSource() being called on an expression, and
# throws an error.
if (getRversion() >= "3.6") {
    shinyjster::testthat_shinyjster()
}
