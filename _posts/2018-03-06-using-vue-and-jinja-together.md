---
layout: post
title:  "Using Vue and Jinja2 together"
date:   2018-03-06 12:42:57 -0600
categories: flask
---

Should be pretty simple, right? It's just a server-side templating engine and
a client-side binding engine. Just put the two in a file and - wait, they both
use mustashes for controlling elements? Well... Poot. Luckily, there's a very
simple solution:


```python
# app.py
import os
import flask

app = flask.Flask(__name__)
app.secret_key = os.urandom(24)


@app.route("/")
def index():
    return flask.render_template("index.html")


@app.template_filter()
def vue(item):
    return "{{ " + item + " }}"


app.run()
```

```html
<!DOCTYPE HTML>
<!-- templates/index.html -->
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width" />
    <title>Hello World!</title>
    <script src="https://cdn.jsdelivr.net/npm/vue@2.5.13/dist/vue.js"></script>
  </head>
  <body>
    <div id="testing">
      <div v-for="message in messages">
      	<!--
        This is the important bit. We take the text that would normally be in
	the handlebars, and pass it to a "vue" filter. The filter then takes
	the object, re-wraps it in handlebars, and then shoves it back in so
	Vue can process it. PS: If you see something like "raw" and "endraw",
	that's because I use Jekyll for these posts, which *also* conflicts
	with Jinja2 and Vue - great, isn't it?
	-->
	{% raw %}{{ "message.text" | vue }}{% endraw %}
      </div>
    </div>
    <script>
      var elem = new Vue({
        el: "#testing",
        data: {
          messages: [
            {"text": "Hello World."},
            {"text": "This is some text!"}
          ]
        }
      });
    </script>
  </body>
</html>
```
