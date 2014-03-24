ClearSkies
==========

ClearSkies is a sync program similar to DropBox, except it does not require a
monthly fee.  Instead, you set up shares between two or more computers and the
sharing happens amongst them directly.

The protocol is documented in its
[own repository](https://github.com/jewel/clearskies).

The software in this repository is a proof-of-concept of the protocol, written
in ruby.  It consists of a background daemon and a command-line interface to
control that daemon.

The ruby code is a little out-of-date in relation to the latest version of the
protocol, as efforts are being focused on a multi-platform C++ version.


Status
------

The software is currently barely functional, in read-write mode only.  It is
not yet ready for production use.  IT MAY EAT YOUR DATA.  Only use it on test
data or on data that you have backed up someplace safe.


Installation
------------

It is currently only tested on Linux.  (It should also work on ruby 1.9 on OS X
and Windows, if not please file an issue.)

If you already have a working ruby 1.9 or 2.0:

```bash
gem install rb-inotify ffi
```

Otherwise, installing dependencies on Ubuntu or Debian:

```bash
apt-get install libgnutls26 ruby1.9.1 ruby-rb-inotify ruby-ffi
```

Note: The version of "ffi" in the Debian stable (wheezy) apt repository has
issues.  The version of "rb-inotify" in Ubuntu 12.04 (precise) also has issues.
In those cases, install the gems via ruby gems:

```bash
apt-get remove ruby-rb-inotify ruby-ffi
apt-get install ruby-dev
gem install rb-inotify ffi
```

Clone this repo:

```bash
git clone https://github.com/jewel/clearskies
```

To start and share a directory:

```bash
cd clearskies
./clearskies start # add --no-fork to run in foreground
./clearskies share ~/important-stuff --mode=read-write
```


This will print out a "SYNC" code.  Copy the code to the other computer, and
then add the share to begin syncing:

```bash
./clearskies attach $CODE ~/important-stuff
```


Contributing
------------

Issues and pull requests are welcome.

The project mailing list is on [google
groups](https://groups.google.com/group/clearskies-dev).  (It is possible to
participate via email if you do not have a google account.)
