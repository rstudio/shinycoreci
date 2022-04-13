function(input, output, session) {
  shinyjster::shinyjster_server(input, output)

  counterServer("counter1")
}
