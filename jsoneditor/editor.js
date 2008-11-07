/*

  Inline JSON Editor
  by
    Andrew Cantino
    Kyle Maxwell
  Copyright 2008
  Version 0.5

*/

function JSONEditorBase() {
  this.history = [];
  this.historyPointer = -1;
  this.builderShowing = true;
  this.ADD_IMG = 'jsoneditor/add.png';
  this.DELETE_IMG = 'jsoneditor/delete.png';
}

function JSONEditor(wrapped, width, height) {
  if (wrapped == null || (wrapped.get && wrapped.get(0) == null)) throw "Must provide an element to wrap.";
  var width = width || 600;
  var height = height || 300;
  this.wrapped = $(wrapped);

  this.wrapped.wrap('<div class="container"></div>');
  this.container = $(this.wrapped.parent());
  this.container.width(width).height(height);
  this.wrapped.width(width).height(height);
  this.container.css("position", "relative");
  
  this.rebuild();
  
  return this;
}
JSONEditor.prototype = new JSONEditorBase();

JSONEditor.prototype.braceUI = function(key, struct) {
  var self = this;
  return $('<a class="icon" href="#"><strong>{</strong></a>').click(function(e) {
    struct[key] = { "??": struct[key] };
    self.rebuild();
    return false;
  });
};

JSONEditor.prototype.bracketUI = function(key, struct) {
  var self = this;
  return $('<a class="icon" href="#"><strong>[</a>').click(function(e) {
    struct[key] = [ struct[key] ];
    self.rebuild();
    return false;
  });
};

JSONEditor.prototype.deleteUI = function(key, struct, layerOnly) {
  var self = this;
  return $('<a class="icon" href="#"><img src="' + this.DELETE_IMG + '" border=0/></a>').click(function(e) {
    var didSomething = false;
    if (struct[key] instanceof Array) {
      if(struct[key].length > 0) {
        struct[key] = struct[key][0];
        didSomething = true;
      }
    } else if (struct[key] instanceof Object) {
      for (var i in struct[key]) {
        struct[key] = struct[key][i];
        didSomething = true;
        break;
      }
    }
    if (didSomething) {
      self.rebuild();
      return false;
    }
    if (struct instanceof Array) {
      struct.splice(key, 1);
    } else {
      delete struct[key];
    }
    self.rebuild();
    return false;
  });
};

JSONEditor.prototype.addUI = function(struct) {
  var self = this;
  return $('<a class="icon" href="#"><img src="' + this.ADD_IMG + '" border=0/></a>').click(function(e) {
    if (struct instanceof Array) {
      struct.push('??');
    } else {
      struct['??'] = '??';
    }
    self.rebuild();
    return false;
  });
};

JSONEditor.prototype.undo = function() {
  if (this.saveStateIfTextChanged()) {
    if (this.historyPointer > 0) this.historyPointer -= 1;
    this.restore();
  }
};
      
JSONEditor.prototype.redo = function() {
  if (this.historyPointer + 1 < this.history.length) {
    if (this.saveStateIfTextChanged()) {
      this.historyPointer += 1;
      this.restore();
    }
  }
};

JSONEditor.prototype.showBuilder = function() {
  if (this.checkJsonInText()) {
    this.setJsonFromText();
    this.rebuild();
    this.builder.show();
    this.wrapped.hide();
    return true;
  } else {
    alert("Sorry, there appears to be an error in your JSON input.  Please fix it before continuing.");
    return false;
  }
};

JSONEditor.prototype.showText = function() {
  this.builder.hide();
  this.wrapped.show();
};

JSONEditor.prototype.toggleBuilder = function() {
    if(this.builderShowing){
      this.showText();
      this.builderShowing = !this.builderShowing;
    } else {
      if (this.showBuilder()) {
        this.builderShowing = !this.builderShowing;
      }
    }
};

JSONEditor.prototype.showFunctionButtons = function() {
  if (!this.functionButtons) {
    this.functionButtons = $('<div class="function_buttons"></div>');
    var self = this;
    this.functionButtons.append($('<a href="#" style="padding-right: 10px;"></a>').click(function() {
      self.undo();
      return false;
    }).text('Undo')).append($('<a href="#" style="padding-right: 10px;"></a>').click(function() {
      self.redo();
      return false;
    }).text('Redo')).append($('<a href="#" style="padding-right: 10px;"></a>').click(function() {
      self.toggleBuilder();
      return false;
    }).text('Toggle View'));
    this.functionButtons.css("position", "absolute");
    this.functionButtons.css("top", this.wrapped.height() + 5);
    this.container.append(this.functionButtons);
    this.container.height(this.container.height() + this.functionButtons.height() + 5);
  }
};

JSONEditor.prototype.saveStateIfTextChanged = function() {
  if (JSON.stringify(this.json, null, 2) != this.wrapped.get(0).value) {
    if (this.checkJsonInText()) {
      this.saveState(true);
    } else {
      if (confirm("The current JSON is malformed.  If you continue, the current JSON will not be saved.  Do you wish to continue?")) {
        this.historyPointer += 1;
        return true;
      } else {
        return false;
      }
    }
  }
  return true;
};

JSONEditor.prototype.restore = function() {
  if (this.history[this.historyPointer]) {
    this.wrapped.get(0).value = this.history[this.historyPointer];
    this.rebuild(true);
  }
};

JSONEditor.prototype.saveState = function(skipStoreText) {
  if (this.json) {
    if (!skipStoreText) this.storeToText();
    var text = this.wrapped.get(0).value;
    if (this.history[this.historyPointer] != text) {
      this.historyTruncate();
      this.history.push(text);
      this.historyPointer += 1;
    }
  }
};

JSONEditor.prototype.historyTruncate = function() {
  if (this.historyPointer + 1 < this.history.length) {
    this.history.splice(this.historyPointer + 1, this.history.length - this.historyPointer);
  }
};

JSONEditor.prototype.storeToText = function() {
  this.wrapped.get(0).value = JSON.stringify(this.json, null, 2);
};

JSONEditor.prototype.getJSONText = function() {
  this.rebuild();
  return this.wrapped.get(0).value;
};

JSONEditor.prototype.getJSON = function() {
  this.rebuild();
  return this.json;
};

JSONEditor.prototype.rebuild = function(doNotRefreshText) {
  if (!this.json) this.setJsonFromText();
  if (this.json && !doNotRefreshText) {
    this.saveState();
  }
  this.cleanBuilder();
  this.setJsonFromText();
  this.alreadyFocused = false;
  this.build(this.json, this.builder);
};

JSONEditor.prototype.setJsonFromText = function() {
  if (this.wrapped.get(0).value.length == 0) this.wrapped.get(0).value = "{}";
  try {
    this.json = JSON.parse(this.wrapped.get(0).value);
  } catch(e) {
    alert("Got bad JSON from text.");
  }
};

JSONEditor.prototype.checkJsonInText = function() {
  try {
    JSON.parse(this.wrapped.get(0).value);
    return true;
  } catch(e) {
    return false;
  }
};

JSONEditor.prototype.logJSON = function() {
  console.log(JSON.stringify(this.json, null, 2));
};

JSONEditor.prototype.cleanBuilder = function() {
  if (!this.builder) {
    this.builder = $('<div class="builder"></div>');
    this.container.append(this.builder);
  } else {
    this.builder.text('');
  }
  
  this.builder.css("position", "absolute").css("top", 0).css("left", 0);
  this.builder.width(this.wrapped.width()).height(this.wrapped.height());
  this.wrapped.css("position", "absolute").css("top", 0).css("left", 0);        
};

JSONEditor.prototype.edit = function(e, key, struct, kind){
  var self = this;
  var form = $("<form></form>").css('display', 'inline');
  var input = document.createElement("INPUT");
  input.value = e.text();
  var onblur = function() {
    var val = input.value;
    if(kind == 'key') {
      struct[val] = struct[key];
      if (key != val) delete struct[key];
    } else {
      struct[key] = val;
    }
    e.text(val);
    e.get(0).editing = false;
    if (key != val) self.rebuild();
    return false;
  };
  $(input).blur(onblur);
  $(form).submit(onblur).append(input);
  $(e).html(form);
  input.focus();
};

JSONEditor.prototype.editable = function(text, key, struct, kind) {
  var self = this;
  var elem = $('<span class="editable" href="#"></span>').text(text).click(function(e) {
    if (!this.editing) {
      this.editing = true;
      self.edit($(this), key, struct, kind);
    }
    return true;
  });
  
  // Auto-edit '??' keys and values.
  if (text == '??' && !this.alreadyFocused) {
    this.alreadyFocused = true;
    elem.click();
    $(this).oneTime(100, function() { // Because JavaScript is annoying and we need to focus once the current stuff is done.
      elem.find('input').focus().select();
    });
  }
  return elem;
}

JSONEditor.prototype.build = function(json, node, parent, key) {
  if(json instanceof Array){
    var bq = $(document.createElement("BLOCKQUOTE"));
    bq.append($("<div>[</div>"));
    
    if (parent) bq.prepend(this.deleteUI(key, parent));
    bq.prepend(this.addUI(json));

    for(var i = 0; i < json.length; i++) {
      var innerbq = $(document.createElement("BLOCKQUOTE"));
      this.build(json[i], innerbq, json, i);
      bq.append(innerbq);
    }
    
    bq.append($("<div>]</div>"));
    node.append(bq);
  } else if (json instanceof Object) {
    var bq = $(document.createElement("BLOCKQUOTE"));
    bq.append($('<div>{</div>'));

    if (parent) bq.prepend(this.deleteUI(key, parent, true));
    bq.prepend(this.addUI(json));

    for(var i in json){
      var innerbq = $(document.createElement("BLOCKQUOTE"));
      innerbq.append(this.editable(i.toString(), i.toString(), json, 'key').wrap('<b class="key"></b>').parent());
      innerbq.append(document.createTextNode(': ')); 
      this.build(json[i], innerbq, json, i);
      bq.append(innerbq);
    }
    
    bq.append($('<div>}</div>'));
    node.append(bq);
  } else {
    node.append(this.editable(json.toString(), key, parent, 'value').wrap('<span class="val"></span>').parent());
    if (parent) node.prepend(this.deleteUI(key, parent));
    node.prepend(this.braceUI(key, parent));
    node.prepend(this.bracketUI(key, parent));
  }
};