(function() {

  describe("basic functionality", function() {
    beforeEach(function() {
      return $("#jasmine_content").html("<textarea id=\"t\">\n  {\n    \"name\": \"a.title\",\n    \"description\": \"foo.bar\",\n    \"authors\": [{\n      \"name\": \"p.foo\",\n      \"link\": \"a | @href\"\n    }]\n  }\n</textarea>\n\n<textarea id=\"t_empty1\">{}</textarea>\n<textarea id=\"t_empty2\">{}</textarea>\n<textarea id=\"t_returns_and_tabs\">{\"hello\": \"wo\\nr\\tld\"}</textarea>\n<textarea id=\"t_null\">\n  {\n    \"null\": null\n  }\n</textarea>");
    });
    it("should load from a text area", function() {
      var j;
      j = new JSONEditor($("#t"));
      expect(j.getJSONText().search("a.title")).toBeGreaterThan(-1);
      return expect(j.getJSON()['name']).toEqual("a.title");
    });
    it("should work from an empty text area", function() {
      var j;
      j = new JSONEditor($("#t_empty1"));
      expect(j.getJSONText()).toEqual('{}');
      expect(typeof j.getJSON()).toEqual('object');
      j = new JSONEditor($("#t_empty2"));
      expect(j.getJSONText()).toEqual('{}');
      return expect(typeof j.getJSON()).toEqual('object');
    });
    it("should let you set the json from text", function() {
      var j;
      j = new JSONEditor($("#t_empty1"));
      j.wrapped.get(0).value = '{"hello": "world"}';
      j.setJsonFromText();
      return expect(j.json['hello']).toEqual("world");
    });
    it("should allow return and tab in text", function() {
      var j;
      j = new JSONEditor($("#t_returns_and_tabs"));
      return expect(j.json['hello']).toEqual('wo\\nr\\tld');
    });
    it("should focus on the key when an object property is added", function() {
      var j;
      j = new JSONEditor($("#t_empty1"));
      $('[title="add"]').click();
      return expect($('.key .edit_field').is(':focus')).toEqual(true);
    });
    return it("should handle null values without exceptions", function() {
      var j;
      j = new JSONEditor($("#t_null"));
      console.log(j.getJSON());
      return expect(j.getJSON()['null']).toEqual(null);
    });
  });

}).call(this);
