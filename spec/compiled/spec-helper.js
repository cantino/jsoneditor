(function() {

  beforeEach(function() {
    jQuery.fx.off = true;
    jQuery('#jasmine-content').empty();
    jasmine.Clock.useMock();
    return jQuery.ajaxSettings.xhr = function() {
      return expect("you to mock all ajax, but your tests actually seem").toContain("an ajax call");
    };
  });

  afterEach(function() {
    var events, prop, _results;
    jasmine.Clock.reset();
    events = jQuery.data(document, "events");
    _results = [];
    for (prop in events) {
      _results.push(delete events[prop]);
    }
    return _results;
  });

}).call(this);
