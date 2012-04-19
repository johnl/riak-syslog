# Riak Syslog

`riak-syslog` takes your syslog messages and puts them into a Riak
cluster and then lets you search them using Riak's full text search.

Rather than re-implement the wheel, `riak-syslog` expects that a
syslog daemon will handle receiving syslog messages and will be able
to provide them in a specific format.

## Examples

Once setup, you can query it like this:





## Syslog daemon setup

 The following steps are for use with
`rsyslog` but any syslog daemon that can send syslog messages to a
fifo in a specific format will do.

Create a fifo somewhere. On Debian/Ubuntu
`/var/run/riak-syslog-receiver` is a good place:

    mkfifo /var/run/riak-syslog-receiver

Then configure your syslog daemon to write logs to the fifo in the
right format. For `rsyslog`:

    $template RiaklogFormat,"%FROMHOST%\9%syslogfacility-text%\9%msg%\9%HOSTNAME%\9%syslogpriority%\9%syslogtag%\9%programname%\9%syslogseverity-text%\9%timegenerated:::date-rfc3339%\n"
    *.* |/var/run/riak-syslog-receiver;RiaklogFormat

On Debian/Ubuntu, you can drop it in
`/etc/rsyslog.d/riak-syslog.conf`. Note that you need to specify the
path to your fifo.

## Riak Syslog config

Specify the address of your Riak cluster, the Riak bucket name and the
protocol in `/etc/riak-syslog.yml`.  We'll assume a bucket name of
`riak-syslog`. The `pbc` protocol is recommended for performance, but
http will work just fine:

    host: localhost
    bucket: riak-syslog
		protocol: pbc

## Riak config

### Setup the Riak search pre-commit hook

    curl -X PUT -H "content-type:application/json" http://localhost:8098/riak/riak-syslog --data @-
    {"props":{"precommit":[{"mod":"riak_search_kv_hook","fun":"precommit"}]}}

### Setup the schema

There is a file called `riak-schema` in the riak-dns project
root. Load it using Riak's `search-cmd` tool:

    search-cmd set-schema riak-syslog /full/path/to/riak-schema

### Set the n_val

I use an `n_val` of 2, as I don't want to lose data if a node fails
but it's not critical enough to have 3 replicas.

    curl -X PUT -H "Content-Type: application/json" -d '{"props":{"n_val":2}}' http://localhost:8098/riak/riak-syslog
