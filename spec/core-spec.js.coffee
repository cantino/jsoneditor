describe "basic functionality", ->
  beforeEach ->
    $("#jasmine_content").html """
      <textarea id="t">
        {
          "name": "a.title",
          "description": "foo.bar",
          "authors": [{
            "name": "p.foo",
            "link": "a | @href"
          }]
        }
      </textarea>

      <textarea id="t_empty1">{}</textarea>
      <textarea id="t_empty2">{}</textarea>
      <textarea id="t_returns_and_tabs">{"hello": "wo\\nr\\tld"}</textarea>
    """

  it "should load from a text area", ->
    j = new JSONEditor($("#t"))
    expect(j.getJSONText().search("a.title")).toBeGreaterThan -1
    expect(j.getJSON()['name']).toEqual "a.title"

  it "should work from an empty text area", ->
    j = new JSONEditor($("#t_empty1"))
    expect(j.getJSONText()).toEqual '{}'
    expect(typeof j.getJSON()).toEqual 'object'

    j = new JSONEditor($("#t_empty2"))
    expect(j.getJSONText()).toEqual '{}'
    expect(typeof j.getJSON()).toEqual 'object'

  it "should let you set the json from text", ->
    j = new JSONEditor($("#t_empty1"))
    j.wrapped.get(0).value = '{"hello": "world"}'
    j.setJsonFromText()
    expect(j.json['hello']).toEqual "world"

  it "should allow return and tab in text", ->
    j = new JSONEditor($("#t_returns_and_tabs"))
    expect(j.json['hello']).toEqual 'wo\\nr\\tld'
