---
layout: post
title:  "Status update: one of many web frameworks"
date:   2018-08-22 00:07:00 -0500
categories: flask
---

As a long-due update and follow-up to
[this post]({% post_url 2018-03-06-using-vue-and-jinja-together %}), I'd like
to talk about some progress on some things that I've been doing, in preparation
for my new Flask-based app design. Below will follow timestamps and code snips
about what I've been up to.

### Feb 6, 2018 - First commit to Gigaspoon

After finding the industry-standard Flask validation library... less than
intuitive, I decided to build my own. It was to be a simple project that could
take a set of rules and apply them to incoming values, and to this day, it
manages to remain loyal to that simple task.

### July 5, 2018 - First commit to NotiCast Web

I begin on a project for work, a website using my "standard" users setup, basic
routes, authentication model, etc. The project then gets the models setup
working, as well as each section individually set up into blueprints - as is
nearly standard at this point, but is still rather functional in design; every
route has it's own rendering code, it's own form handling, and a few other
design quirks that were less than subpar.

After working on it for a few months, I come with the idea to make an app that
is both a fully working JavaScript-less backend as well as a reactive
JavaScript frontend. This means that the ability to gather new data, as well as
handle events, should be abstracted in a way that makes each class consistent
in API design, and capable of handling various input and output formats.

### Aug 18, 2018 - The AppRouteView

The project needed to be more structured, in a way where routes represented a
set of rules, rather than a surprisingly-working function. A class was designed
based off the Flask MethodView, called the AppRouteView. It abstracts the input
across JSON or HTML forms (meaning shallow-lists only, for now!), giving a way
to handle various inputs. The object has to also handle templates as well as
where to redirect to after a POST (as not doing so leads to refresh spam).

### auth.py

```python
import gigaspoon as gs
from flask import Blueprint, g

blueprint = Blueprint("auth", __name__, url_prefix="/auth")

from .app_view import AppRouteView, response


class Register(AppRouteView):
    # HTML forms will be redirected to this endpoint
    redirect_to = "auth.login"
    # Jinja2 template, will be called on GET requests
    template_name = "auth/register.html"

    # Express constraints using Gigaspoon decorators; can be assigned
    # externally and used in other routes, as well.
    decorators = [
        gs.validator(gs.v.Length("username", min=4, max=64)),
        gs.validator(gs.v.Length("password", min=6))]

    def handle_post(self, values):
        # Use the `values` item to access values; will abstract to be either
        # JSON values or HTML form values from the POST body
        username = values["username"]
        password = values["password"]
        store_user(username, password)
        # Add a success message after a POST to make sure users get a result
        # When HTML, the message is flashed. When JSON, it is returned as a
        # "message" attribute. A `payload` value can be passed to return an
        # advanced JSON payload, and a `status_code` value can be passed to
        # specify an HTTP status code - handled errors should return 200 for
        # the website, avoiding configured responses to avoid POST-spamming
        return response("Successfully registered user: %s" % username)


class Login(AppRouteView):
    redirect_to = "index"
    template_name = "auth/login.html"

    # Will be returned JSON-serialized from GET requests, and passed as the
    # Jinja2 context on HTTP GET requests
    def populate(self):
        return {
            "is_logged_in": g.user is not None,
            "username": g.user.username if g.user is not None else ""
        }

    def handle_post(self, values):
        # If Gigaspoon values are not found, `values` will fall back to
        # the Flask request, then the Flask JSON
        if not check_login(values["username"], values["password"]):
            # Give a 403 code, which will trigger the "warning" notification
            # category and give a 403 to JSON requests
            return response("Username or password not found: %s" % username,
                            status_code = 403)
        return response("Successfully logged in as %s" % username)


blueprint.add_url_rule("/register", view_func=Register.as_view())
blueprint.add_url_rule("/login", view_func=Login.as_view())
```

### templates/auth/register.html

```html
{%- raw -%}
<h1>Register</h1>
<form action="{{ url_for("auth.register") }}" method="POST">
  <!-- In-HTML usage of validator "populated" methods! -->
  <input type="text" name="username" id="username" value="" required
    minlength="{{ g.username_validator.min }}"
    maxlength="{{ g.username_validator.max }}" />
  <input type="password" name="password" id="password" value="" required
    minlength="{{ g.password_validator.min }}"
    maxlength="{{ g.password_validator.max }}" />
</form>
{% endraw %}
```

### templates/auth/login.html

```html
{%- raw -%}
<h1>Log In</h1>
<!-- Will use data given in the `populate()` command -->
{% if is_logged_in %}
<h3>You are already logged in as: <b>{{ username }}</b></h3>
{% endif %}
<form action="{{ url_for("auth.login") }}" method="POST">
  <!-- In-HTML usage of validator "populated" methods! -->
  <input type="text" name="username" id="username" value="" required
    minlength="{{ g.username_validator.min }}"
    maxlength="{{ g.username_validator.max }}" />
  <input type="password" name="password" id="password" value="" required
    minlength="{{ g.password_validator.min }}"
    maxlength="{{ g.password_validator.max }}" />
</form>
{% endraw %}
```

---

The code for this is not much more than would be used in functions, but this
gives the ability to change some components without affecting others, and
overall makes every route into a more structured utility. I, for one, am rather
fond of this system.

### Aug 22, 2018 - Plans moving forwards

So far, I've taken some great steps with this framework. However, I do not yet
have a VueJS controller properly working on each page, which I consider to be
a flaw and a potentially differing design decision from what I have now. The
shortest term goal is to noscript the current notifications system and add a
toasts bar for session-flashed notifications.

Over time, I'd like to get a VueJS controller put in place, letting the
end of each populated "group" have a dummy value which can be controlled later
by VueJS data sources being updated. This could result in creating a backend
that renders the initial UI, but then at runtime can add more content to the
UI without ever having to reload the page.

I'd like to put this project into a larger framework that I can use for
rapidly prototyping new applications, with an extension allowing utility
methods, as well as a base distribution to begin working off, which can include
an authentication setup, a notifications setup, and the basic "base.html"
structure I have for most projects.
