beforeEach ->
  jQuery.fx.off = true
  jQuery('#jasmine-content').empty()
  jasmine.Clock.useMock()

  jQuery.ajaxSettings.xhr = ->
    expect("you to mock all ajax, but your tests actually seem").toContain "an ajax call"

afterEach ->
  jasmine.Clock.reset()

  # Clear any jQuery live event bindings
  events = jQuery.data(document, "events")
  delete events[prop] for prop of events
