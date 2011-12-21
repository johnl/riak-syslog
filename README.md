# Riak Syslog

## Setup

mkfifo /tmp/riak-syslog-receiver

### config

`/etc/riak-syslog.yml`

host: localhost
bucket: riak-syslog


### riak bucket config

curl -X PUT -H "content-type:application/json" http://localhost:8098/riak/riak-syslog --data @-
{"props":{"precommit":[{"mod":"riak_search_kv_hook","fun":"precommit"}]}}

search-cmd set-schema riak-syslog /full/path/to/riak-schema

# TODO

+ fix silly fake tab character tokenizer
