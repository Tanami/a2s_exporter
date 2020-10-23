# a2s_exporter
![a screenshot](https://raw.githubusercontent.com/Tanami/a2s_exporter/master/example.png)
Prometheus Exporter for A2S protocol-compatible servers.

## Dependencies
```
cpanm install Coro AnyEvent AnyEvent::Handle::UDP Data::Dumper::Perltidy Prometheus::Tiny
```

## About
I wrote this tool to provide global statistics on bunnyhop game servers. It uses a very simple mechanism based on `AnyEvent::Handle::UDP` for submitting queries and can probably easily scale to thousands of servers.

A2S queries provide the following information:
 - Server name, tags, etc
 - Player counts, kills
 - Current map

Currently, it only tracks the number of players.

## Warning!
**This program has not been tidied, and may have unexpected behaviour!**

## TODO
 - Add a timer routine to query the masterserver list for servers with specific tags
 - Add all bunnyhop servers to the list
 - Make the lookup table mechanism a bit nicer?
 - Move the hardcoded values out into a hash
 - Add map tracking (with prometheus labels)
