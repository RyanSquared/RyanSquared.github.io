---
layout: post
title:  "Thoughts on the recent (5.7.0) NPM bug."
date:   2018-02-23 09:25:00 -0600
categories: npm node security
---

There was a bug in NPM recently, as of version 5.7.0. Let's get right into the
juicy details: Running as a user, but getting escalated to sudo, would not mark
you as "root" when running commands with `npm`. See the problem? Here's the
details from [the GitHub issue][gh-issue-npm-npm-19883]:

> This issue has been happening ever since 5.7.0 was released a few hours ago.
It seems to have completely broken my filesystem permissions and caused me to
have to manually fix the permissions of critical files and folders. I believe
that it is related to the commit 94227e1 which is traversing and running chown
on the wrong, often critical, filesystem files and folders.
>
> By running sudo npm under a non-root user (root users do not have the same
effect), filesystem permissions are being heavily modified. For example, if I
run `sudo npm --help` or `sudo npm update -g`, both commands cause my
filesystem to change ownership of directories such as `/etc`, `/usr`, `/boot`,
and other directories needed for running the system. It appears that the
ownership is recursively changed to the user currently running npm.
>
> I found that a selection of directories in `/` were owned by a non-root user
after running `sudo npm` and many binaries in `/usr/bin` stopped working as
their permissions were changed. People experiencing this bug will likely have
to fully reinstall their system due to this update.
>
> `npm update -g` as `root`:
>
> No output, all packages up to date. Likely still causes a `chown` to be run
silently to `root:root`.
`drwxr-xr-x 10 root root 129 Feb 22 03:39 /usr`
>
> Then doing a `su jared` (a non-root user):
> 
> `sudo npm update -g` as `jared`:
>
> Sometimes `EACCES` or `EPERM` output, almost always corrupts the filesystem.
`drwxr-xr-x 10 jared jared 129 Feb 22 03:39 /usr`

## The important bits

- `npm` is flawed, as it is software, and all software is flawed
- `/etc` should never be flawed as it's neccessary to run a system
- We ran `npm` affecting `/etc` knowing this
- People could have to _reinstall their entire OS_ because of this issue

### This is unacceptable

We, as people who acknowledge that there are flaws in software, should not be
as trusting as we are. We shouldn't give programs the ability to mutilate our
system and potentially make it unusable, just because we want to install 
`lolcat` to make things show up as a nice and pretty rainbow colour (yes,
lolcat is ruby, not JS, but that's not the point).

I could make this into a post about how awful Node.js is, or how everyone
should (and yes, you really should) go use [Yarn][yarnpkg] instead. However,
instead, I'm going to help talk about how to solve the root issue - that we
blindly trust software with all of our data, and complete control over our
system.

With an organization I work with - Hashbang, Inc. - we let users run amok on a
shared system, doing as they please. These users typically want to install some
things to make their lives easier, but I'm ~~lazy~~ security-oriented, so we
needed a way to let users install software without being able to destroy the
system.

## The solution

We need a directory where users can put things that don't need to be permanent,
that shouldn't be able to affect other users, that can be replaced if needed,
and don't need root permissions which - if taken away - can cause the system
to become irreparably broken. This directory would be useful for storing their
configuration files, their media, and their programs. Wait... That's just-

__`$HOME` - The directory built by you, for you.__

Users have their own directory. They're allowed to put whatever they want in
that directory. They can store NSA secrets, massive amounts of material used
for personal satisfaction, games, and other things. So, I'm going to go out on
a limb and suggest something very dangerous -- what if we put binaries,
libraries, and configuration files in this directory?

### Binaries and Libraries

Here's some stuff that we have configured for Hashbang, Inc.

```sh
# Lua
# Use `--local`
alias luarocks-5.1="lua5.1 /usr/bin/luarocks"
alias luarocks-5.2="lua5.2 /usr/bin/luarocks"
alias luarocks-5.3="lua5.3 /usr/bin/luarocks"
# Need to do 5.1 last, as it adds to LUA_PATH, which would be picked up by the
# other PATH commands.
eval `lua5.3 /usr/bin/luarocks --bin path`
eval `lua5.2 /usr/bin/luarocks --bin path`
eval `lua5.1 /usr/bin/luarocks --bin path`

# Python, and a few other things
# For Python, use `--user`
export PATH="$HOME/.local/bin:$PATH"

# Ruby
# Ruby automatically installs as user
export PATH="$HOME/.gem/bin:$PATH"

# Node.js
export PATH="$HOME/.npm-packages/bin:$PATH"
export NODE_PATH="$HOME/.npm-packages/lib/node_modules"
export NPM_CONFIG_PREFIX="$HOME/.npm-packages"
```

Want to install Flask, for Python? `pip install --user flask`. Bam. Want to run
Jekyll to build this site? `gem install jekyll`. Bam. Want to install luacheck
and lint your code? `luarocks-5.3 install --local luacheck`. Bam. No issues, no
problems, and it all works.

As you can see, Node.js is a bit tricky to set up in this way, but it is
definitely possible. Almost every package manager has a "user" variant, so
you can install software as a user rather than as root.

### Configuration

There's a beautiful little folder on all of my systems, called `$HOME/.config`.
All of my configuration lies in there - even if programs expect it to be in
just `$HOME`, I'll link it into there. This folder is designated by a variable
`$XDG_CONFIG_HOME` (documentation [here][xdg-config-docs]). Feel free to design
programs that point to this directory (assuming you use `$XDG_CONFIG_HOME` and
don't just hardcode it in), as well as force current programs to use it.
Instead of telling your programs to use a system-wide configuration, have them
run as your user, using your user configuration.

Programs such as i3wm, awesomewm, Mopidy, htop, pylint, and systemd all use the
`$XDG_CONFIG_HOME` directory.

#### Wait - systemd? I can run `systemctl` as a user?

Holy Jesus, the amount of people who don't know about this is absolutely
astonishing. Yes, you can run your daemons, which before were in a system-wide
config directory, as a user. In fact, Hashbang, Inc. even has an example
for a [pretty simple webserver][dotfiles-systemd-unit]. You can run anything
you want under these - assuming you can start the programs as a regular user.
No longer will you have to set up a `@reboot` crontab and hope it doesn't
crash, and no longer will you be putting `User=` in your system services. All
you have to do is use `systemctl --user`.

## Ending Notes

Whenever you plop a `sudo` in your command, think about whether you need it.
Think about whether what you're about to run is worth risking your entire
system. Do you really need a [steam locomotive][sl] running along your screen
as a little easter egg, or can you install it as a user program? I hope that
by reading this, you can convince yourself that you'll never use `sudo` unless
it's really worth it, and you'll continue to leave your root system as pure as
the day you first started it.

[gh-issue-npm-npm-19883]: https://github.com/npm/npm/issues/19883
[yarnpkg]: https://yarnpkg.com/en/docs/install
[xdg-config-docs]: https://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html
[dotfiles-systemd-unit]: https://github.com/hashbang/dotfiles/blob/master/hashbang/.config/systemd/user/SimpleHTTPServer.service
[sl]: https://github.com/mtoyoda/sl
