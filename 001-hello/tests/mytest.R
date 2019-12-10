app <- ShinyDriver$new("../", seed = 1199)
app$snapshotInit("mytest")

app$snapshot()
app$setInputs(bins = 10)
app$snapshot()
app$setInputs(bins = 50)
app$snapshot()
