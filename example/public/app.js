window.App = function(url, verbs) {
  this.verbs = verbs;
  this.stream = new EventSource(url);
  this.el = $('#posts');
  this.bindEvents();
};

$.extend(App.prototype, {
  bindEvents: function() {
    var that = this;

    this.stream.addEventListener('open', function() {
      console.log('Listening to ' + this.url);
    });

    // Bind create, update, and destroy
    $.each(this.verbs, function(index, verb) {
      that.stream.addEventListener(verb, function(event) {
        var post = JSON.parse(event.data);
        console.log(verb, post);
        that[verb](post);
      });
    });
  },

  attributes: ['id', 'content', 'update_count', 'lastUpdated'],

  render: function(post) {
    post.lastUpdated = new Date(post.updated_at).toLocaleString();

    var cols = $.map(this.attributes, function(attr) {
      return $('<td>').text(post[attr]);
    });

    return $('<tr>').attr('id', 'post' + post.id).append(cols);
  },

  find: function(post) {
    return this.el.find('#post' + post.id);
  },

  create: function(post) {
    this.el.prepend(this.animate(this.render(post), 'bounceInLeft'));
  },

  update: function(post) {
    var tmpl = this.render(post), row = this.find(post);
    if (!row.length) { return this.create(post); }

    this.animate(row, 'shake', function() {
      row.replaceWith(tmpl);
    });
  },

  destroy: function(post) {
    var row = this.find(post);
    this.animate(row, 'bounceOutRight', function(){ row.remove(); });
  },

  animate: function(el, name, callback) {
    el.removeClass().addClass('animated ' + name);
    return callback ? setTimeout(callback, 600) : el;
  }
});

$(document).ready(function() {
  new App('/stream/posts', ['create', 'update', 'destroy']);
});
