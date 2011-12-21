# Riak Syslog

## Setup

    mkfifo /tmp/riak-syslog-receiver

### config

`/etc/riak-syslog.yml`

    host: localhost
    bucket: riak-syslog
		protocol: pbc

### riak bucket config

Assuming a bucket name of `riak-syslog`:

#### Setup the riak search precommit hook

    curl -X PUT -H "content-type:application/json" http://localhost:8098/riak/riak-syslog --data @-
    {"props":{"precommit":[{"mod":"riak_search_kv_hook","fun":"precommit"}]}}

#### Setup the schema

There is a file called `riak-schema` in the riak-dns-project
root. Load it using Riak's `search-cmd` tool:

    search-cmd set-schema riak-syslog /full/path/to/riak-schema

### Set the n_val

I use an `n_val` of 2, as I don't want to lose data if a node fails
but it's not critical enough to have 3 replicas.

    curl -X PUT -H "Content-Type: application/json" -d '{"props":{"n_val":2}}' http://localhost:8098/riak/riak-syslog

# TODO

+ fix silly fake tab character tokenizer
