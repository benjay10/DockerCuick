# DockerCuick

A script that makes `docker compose` commands much shorter to type, by using
aliases for commands, and glob-style searching through both commands and
services. Give your fingers some rest and get deploying services in Docker
Compose done faster.

For example, write this:

```
dc u,l migr
```

instead of this:

```
docker compose up -d migrations-publication-triplestore ; docker compose logs --tail 1000 -f --no-log-prefix migrations-publication-triplestore
```

What this simple script supports for now:

* Operations on services: start, stop, up, down, pull, stats, ...
  - Including passing options
  - This can be done in sequences
* Search through service names, for when you can't remember the exact name of a
  service
* If the script's functionality is insufficient, use it as an alias for `docker
  compose`

What it can not do:

* No support (yet) for commands that are not whitelisted. Only the basics are
  supported.

## Installation

### Preparation

This script is written in Tcl 8.6, and uses `libyaml`, a common YAML
implementation in C. You should be able to install these easily on most common
Linux distributions. For example:

```
# On Arch Linux
pacman -S tcl libyaml
# On Fedora
dnf install tcl libyaml
# On Ubuntu
apt install tcl libyaml-0-2
# ...
```

You also need to install some dependencies and bindings for executing C code in
Tcl. This is a lot trickier. Hopefully, the included installation script makes
this work for you. If not, there is also the option to manual install them.
Below are the intructions on using the installation scipt, followed by the
alternative manual installation guide.

#### Installation script

There is an `install.tcl` script in the root of this repository. This Tcl
script will create a `src` and `build` directory inside the repository
directory. The `src` directory will be used to clone the git repositories, and
the built sources will be placed in the `build` directory. Make sure to execute
the installation script whith this repository directory as your working
directory, like so:

```
cd DockerCuick/
tclsh ./install.tcl
```

After installation, you can remove the `src` directory if you really must, or
you can leave it in place if you want to update the dependencies later. To
update them, you just run the same script again. This will remove the `build`
directory, `git pull` the source code and rebuild the needed packages.

Don't remove the build directory. This directory contains the needed packages
for the `dc` script. The script will refer to the `build` directory that is in
the same directory, so you must always keep the `dc` script and the `build`
directory in the same place.

<details>

<summary>
<h4>Manual installation (requires root privileges)</h4>
</summary>

Prepare a directory to download, build and install some modules. The next
sections will be executed in that directory.

<h5>Install CriTcl</h5>

Follow the installation guide
[here](https://github.com/andreas-kupries/kettle/blob/master/embedded/md/doc/files/kettle_installer.md)
or try these quick steps (you might need to run these with elevated privileges,
depending on your system):

```
git clone https://github.com/andreas-kupries/critcl.git
cd critcl
tclsh ./build.tcl install    # or ./build.tcl install
cd ..
```

<h5>Install Kettle</h5>

Follow the installation guide
[here](https://github.com/andreas-kupries/kettle/blob/master/embedded/md/doc/files/kettle_installer.md)
or try these quick steps (you might need to run these with elevated privileges,
depending on your system):

```
git clone https://github.com/andreas-kupries/kettle.git
cd kettle
tclsh ./kettle ./build.tcl install
cd ..
```

<h5>Install TclYAML</h5>

Follow the installation guide
[here](https://github.com/andreas-kupries/tclyaml.git) or try these quick steps
(you might need to run these with elevated privileges, depending on your
system):

```
git clone https://github.com/andreas-kupries/tclyaml.git
cd tclyaml
tclsh ./build.tcl install    # or ./build.tcl install
cd ..
```

</details>

### Install the `dc` script

Put the `dc` script in your shell path. On Bash, you can quickly do this by
adding something like the following line in `~/.bashrc`:

```
PATH=$HOME/git/repo/for/DockerCuick/:$PATH
```

and don't forget to restart Bash :) . Also make sure that the script is
executable:

```
chmod +x dc
```

Alternatively, you can make a link to the `dc` script from within a directory
that already is inside your `PATH`:

```
ln -s /folder/in/PATH/dc /git/repo/for/DockerCuick/dc
```

## Recommendations

If you have multiple `docker-compose` project YAML files, say for example you
also have a `docker-compose.overrides.yml`, you might want to make a `.env`
file in the root of the Docker Compose project to allow the `dc` script to also
search through those files for services. If not, the script will only look
through the default `docker-compose.yml` file.

An example `.env` file looks like this:

```
COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml:docker-compose.override.yml
```

## Usage

### Grammar syntax

In the following sections, you will see syntax like `{a|*start}` and
`[*<servicename>]...`. A short explanation:

* `[]` mean optionality, you don't have to supply that argument
* `{}` indicate a mandatory argument
* `|` means 'or'
* `*` means, for lack of better notation, any glob-style pattern that matches
  the word after the asterisk
* `<>` mean to interpret the contents of these brackets as a human, replacing
  it with the intended word
* `...` attached to the end of a word means that this argument type can be
  repeated
* any other word in the command is to be used in a literal manner

So `{a|*start}` means that argument `a` is allowed, or any pattern like `sta`,
`art`, ... that uniquely matches to the word `start`. Also,
`[*<servicename>]...` means any amount of patterns that uniquely matches a
service's name.

There are a couple of "modes" you can use the script in. Lets start with the
simplest mode and build our way up.

### As an alias

You can use this script almost as an alias for the long `docker compose`
command. You can write

```
dc -- up -d webapp
```

as a way to shorten the command

```
docker compose up -d webapp
```

In a sense, the `dc --` is equivalent to the `docker compose`.

As a mnemonic, think of the `--` as a way to signal the end of the options to
the `dc` script and to prevent further interpretation. It will just forward
whatever follows directly to the `docker compose` command. This mechanism is
widely used throughought Bash builtin functions, the `grep` utility, and
others.

### To search services

Forgot the long name of a service, or doubt if a command will manage the
correct service? You can always use the search function to find what you are
looking for. Write a search like so:

```
dc ? [*<servicename>]...
```

This means you start the search with the `?` subcommand and supply zero or more
search patterns. For example:

```
dc ?
```

will list all the services in your project. Use:

```
dc ? web data
```

And you will get for both the `web` and `data` search patterns a summary of
services that match that pattern. E.g. in this case this might mean `webapp`
and `database`.

If there are multiple matches for your search, you can narrow down the results
by typing more characters to uniquely identify a single service, or use search
modifiers to select the shortest, longest or exact match. Imagine there are 3
services in your project that match your search `data`: `database`,
`database-replicator` and `data-warehouse`. You could type `datab` to match
`database` and `database-replicator`. You could then narrow it down to a single
service by using `+datab`, with a plus symbol at the start of the pattern,
which matches the longest servicename `database-replicator`. A minus symbol
will match the shortest servicename. A period will only match the exact
pattern: `.database` will only match `database` and will not match
`database-replicator`.

**NOTE:** make sure to take a look at the "Reference" section below for "Search
modifiers" for narrowing down your searches.

### To manage services

Start, stop, restart, up, down, ... of a service or services, or get logs or
statistics of services with short subcommand aliases or patterns with the
following syntax:

```
dc {a|o|r|u|d|s|l|p|*<subcommand>} [*<servicename>]...
```

This just means that you can use one of the available aliases of subcommands
like `a` for start and `o` for stop, or use a search pattern that uniquely
identifies one, followed by a list of zero or more search patters for services.
You can use search modifiers for narrowing down your searches.

For example:

```
dc a
```

will start the whole Docker Compose project because the empty search pattern
matches (as an edge case) all services in the project, and

```
dc d web
```

will stop and remove (down) the container for the `webapp` service in the
project.

**NOTE:** Refer to the "Reference" section below for a complete list of the
subcommand aliases, the default options and to pass additional options.

### To sequence commands

You can sequence subcommands, so that they are executed in sequence as if you
would chain `dc` commands. Formally this would look like:

```
dc {a|o|r|u|d|s|l|p|*<subcommand>}[,a|o|r|u|d|s|l|p|*<subcommand>]... [*<servicename>]...
```

but looking at some examples makes this way easier. For example, this popular
command

```
dc a,l web
```

starts the webapp service and immediately inspects its logs. This command gives
the same result as running `dc a web ; dc l web`, which, in turn, is short for
`docker compose start webapp ; docker compose logs --tail 1000 -f webapp`.

### To manage services with options

If you need to pass specific options to your subcommand(s), you can do so
between square brackets after each subcommand (alias or pattern). Make sure to
not use spaces between the subcommand and the opening bracket. Spaces are
allowed within the brackets. In more formal syntax, this would look like:

```
dc {a|o|r|u|d|s|l|p|*<subcommand>}\[<options with spaces>\] [*<servicename>]...
```

but this starts to look silly because the `[]` are part of how the grammar
rules are written. Let's look at some examples instead:

```
dc u[-d],l web
```

executes `up -d webapp` and `logs webapp`. The content of the `[]` is passed as
options to the `up` subcommand.

```
dc l[-f --tail 1000] web
```

executes `logs -f --tail 1000 webapp`. See how spaces are allowed whithin the
`[]`.

**NOTE:** in the above two examples, the options passed to the subcommands are
part of the defaults that are already passed to `docker compose` for those
respective subcommands, but they serve as an easy example here. Refer to the
"Reference" section below for a better overview.

### To execute a command in a service

This is not so special, as it looks similar to the other modes. You can execute
a command on a service, just like with the regular `docker compose`, but with
the benefit of the matching on the command and the services. To execute a
command, use

```
dc {e|*exec} {*<servicename>} {<command with multiple options>}
```

For example:

```
dc e webapp curl -X POST http://localhost/request
```

where there can only be one service name and all following terms form the
command to be executed in that service.

## Reference

The following lines sum up all the possible syntaxes for the `dc` command.

```
dc -- {<docker compose subcommands and optional services>}
dc ? {*<servicename>}...
dc {a|o|r|u|d|s|l|p|*<subcommand>}[\[<options with spaces>\]][[,a|o|r|u|d|s|l|p|*<subcommand>][\[<options with spaces>\]]]... [*<servicename>]...
dc {e|*exec} {*<servicename>} {<command with multiple options>}
```

### Supported subcommands

Subcommands are the commands that you send to the `docker compose` command,
e.g. start, stop, down, ... The following list shows the subcommands that are
supported.

```
rm up down exec logs pull stop start stats restart
```

You can use these subcommands directly after the `dc` command.

### Subcommand aliases

The `dc` command understands aliasses for subcommands as well as patterns that
uniquely match the subcommand. In the table below you can find the alias that
corresponds to the full subcommand.

| Alias | Subcommand |
| ----- | ---------- |
| a     | start      |
| o     | stop       |
| r     | restart    |
| d     | down       |
| u     | up         |
| l     | logs       |
| s     | stats      |
| p     | pull       |
| e     | exec       |

There is no `rm` alias, because this can also be achieved with `down`; this
means the `d` subcommand alias. You could still use the full subcommand `rm`.

The `restart` subcommand is somewhat redundant, because it can be achieved with
the subcommand alias sequence `o,a`, however, it is kept as an alias, because
it is often used and the alias sequence is a bit annoying to type.

### Subcommand default options

Some subcommands are given default options. They are given automatically to
`docker compose`. The table below shows the subcommand and the default options.

| Subcommand | Default options  |
| ---------- | ---------------- |
| `logs`     | `--tail 1000 -f` |
| `up`       | `-d`             |

### Subcommand conditional options

Some options are given by default, only if certain conditions apply. The table
below show these options for the conditions.

| Subcommand | Conditions       | Default options   |
| ---------- | ---------------- | ----------------- |
| `logs`     | only one service | `--no-log-prefix` |

### Search modifiers

In some cases, your search pattern for subcommands or services might give more
than one result. You could give more characters to your search pattern to
narrow down the search, but you could also use modifiers to choose the
shortest, longest, or exact match. These modifiers are the first character of
your subcommand or servicename search pattern.

| Modifier | Result                  |
| -------- | ----------------------- |
| +        | Longest match possible  |
| .        | Exact match             |
| -        | Shortest match possible |

## Limitations

Sometimes the syntax of a certain feature is not the best, but can not always
easily be improved. For example, passing options to subcommands is done with
square brakets because Bash also interprets the command. Using normal brackets
causes Bash to complain about syntax errors. The same applies to choosing
characters as search modifiers and other things. Hopefully we chose the easiest
and most easy to remember alternatives.

