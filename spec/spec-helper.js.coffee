beforeEach ->
  jQuery.fx.off = true
  jQuery('#jasmine_content').empty()
  jasmine.Clock.useMock()

  jQuery.ajaxSettings.xhr = ->
    expect("you to mock all ajax, but your tests actually seem").toContain "an ajax call"

afterEach ->
  jasmine.Clock.reset()
