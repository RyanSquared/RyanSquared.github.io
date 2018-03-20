---
layout: post
title:  "Using systemd timers instead of cron"
date:   2018-03-20 17:34:05 -0500
---

Linux users love to loathe systemd. It's a tool that (for all it's useful for)
still comes with an almost embarassing amount of quirks, including things only
working on certain values in units, breaking the default functionality of
user-started daemons, and just being a complete monolith. But, this isn't a
post for trash-talking systemd. It's here, we might as well use it.

## Timers

An essential component to systemd that is often overlooked is it's ability to
replace `cron`, a tool that has in the past been used for escaping namespacing
and permissions enforcements due to the way the daemon runs. This unfortunately
is something that happens with all daemons that are started outside of the
user's namespace, except for ones managed by systemd. Why? I dunno lol.

The Arch Wiki guide has a link
[here](https://wiki.archlinux.org/index.php/Systemd/Timers) if you want to view
the pros/cons of replacing cron with systemd.

Let's take a stupid-simple timer of the name `example.timer` that runs weekly:

```
[Unit]
Description=Some arbitrary, safe text that systemd won't barf on.

[Timer]
OnCalendar=weekly

[Install]
WantedBy=timers.target
```

This is the simplest timer that will automatically start `example.service` (and
yes, the filename is linked to which unit is started) once every week. The
following values can be used as a quick version of "OnCalendar":

- minutely
- hourly
- daily
- monthly
- weekly
- yearly
- quarterly
- semiannually

But, let's say you want some more fine-tuned control over it. What should you
do then? Well, cron's format was pretty simple to understand:

- `*/5` meant "every fifth"
- `5` meant "every time the value is 5"
- `*` by itself meant "every time"

So we could write specifications for 4 AM on the first of the month:

```
0 4 1 * * echo 
```

With systemd, it's a bit more fine-grained:

```
OnCalendar=* *-*-1 04:00:00
```

As you can probably guess, the format is as follows:

```
OnCalendar=<weekday [optional]> <year>-<month>-<day> <hour>:<minute>:<second>
```

Ranges that could be used should be specified using `..` between the first and
the last value. For example, the following will only run on weekdays:

```
OnCalendar=Mon..Fri *-*-* 08:00:00
```

I may or may not be using that to make sure I'm clocked into work.

## Hooks

systemd has a handy utility where the values after a "@" when enabling a unit
will be "injected" into the unit where "%I" is referenced. It's use is
demonstrated below.

Let's say that, for example, you want to replace the `cron` functionality of
`@daily`, `@hourly`, `@reboot` and so on, but still want the convenience of
having `crontab -e` without worrying about systemd. Well, as of systemd
version 230, we now can do that using a very simple setup:

```
# cron@.timer
[Unit]
Description=%I timer simulating /etc/cron.%I
PartOf=crontab.target
RefuseManualStart=yes
RefuseManualStop=yes

[Timer]
# Added support for %I in systemd version 230
OnCalendar=%I
Persistent=yes
```

```
# cron@.service
[Unit]
Description=%I job for /etc/cron.%I
RefuseManualStart=yes
RefuseManualStop=yes
ConditionDirectoryNotEmpty=/etc/cron.%I

[Service]
Type=oneshot
IgnoreSIGPIPE=no
WorkingDirectory=/
ExecStart=/bin/run-parts --report /etc/cron.%I
```

Then, we can run:

```sh
for timeset in daily hourly monthly weekly; do
  sudo systemctl enable cron@${timeset}.timer
done
```

That's all for now. Poke me if you think I should add more info.
