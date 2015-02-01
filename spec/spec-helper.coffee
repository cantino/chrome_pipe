beforeEach ->
  $.fx.off = true
  jasmine.Clock.useMock()

  $.ajaxSettings.xhr = ->
    expect("you to mock all ajax, but your tests actually seem").toContain "an ajax call"

afterEach ->
  $('#jasmine-content').empty()
  $('body').removeClass()
  jasmine.Clock.reset()

  # Clear any jQuery events
  $('body').off()
  $(document).off()
