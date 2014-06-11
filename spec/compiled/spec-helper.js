(function() {

  beforeEach(function() {
    jQuery.fx.off = true;
    jQuery('#jasmine_content').empty();
    jasmine.Clock.useMock();
    return jQuery.ajaxSettings.xhr = function() {
      return expect("you to mock all ajax, but your tests actually seem").toContain("an ajax call");
    };
  });

  afterEach(function() {
    return jasmine.Clock.reset();
  });

}).call(this);
