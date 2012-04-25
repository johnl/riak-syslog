# Riak Syslog

`riak-syslog` takes your syslog messages and puts them into a Riak
cluster and then lets you search them using Riak's full text search.

Rather than re-implement the wheel, `riak-syslog` expects that a
syslog daemon will handle receiving syslog messages and will be able
to provide them in a specific format.

## Examples

Once setup, you can query it like this:

    $ riak-syslog search "accepted publickey root"
    
     host   time             program  log                                                            
    --------------------------------------------------------------------------------------------------
     ho106  Dec-17 03:20:15  sshd     Accepted publickey for root from 10.132.xxx.xxx port 58297 ssh2
     ho178  Dec-23 22:55:18  sshd     Accepted publickey for root from 10.153.xxx.xxx port 56067 ssh2 
     ho224  Jan-02 00:29:10  sshd     Accepted publickey for root from 10.153.xxx.xxx port 46940 ssh2 
     ho280  Nov-29 03:19:43  sshd     Accepted publickey for root from 89.240.xxx.xxx port 60751 ssh2 
     ho113  Jan-12 16:51:37  sshd     Accepted publickey for root from 10.132.xxx.xxx port 56915 ssh2
     ho126  Jan-10 19:29:01  sshd     Accepted publickey for root from 10.153.xxx.xxx port 65232 ssh2 
     ho114  Nov-29 10:32:33  sshd     Accepted publickey for root from 10.153.xxx.xxx port 60020 ssh2 
     ho211  Jan-24 08:19:40  sshd     Accepted publickey for root from 89.240.xxx.xxx port 48496 ssh2 
     ho207  Mar-28 15:04:19  sshd     Accepted publickey for root from 10.153.xxx.xxx port 54484 ssh2 
     ho125  Jan-23 03:20:52  sshd     Accepted publickey for root from 10.132.xxx.xxx port 43904 ssh2
    --------------------------------------------------------------------------------------------------

Or limit the search to logs from the last 30 days for a particular program:

    $ riak-syslog search --from="30 days ago" program:postfix NOQUEUE
    
     host       time             program  log                                                     
    -----------------------------------------------------------------------------------------------
     srv-xxxxx  Mar-28 07:55:12  postfix  NOQUEUE: reject: RCPT from unknown[27.41.136.41]: 554...
     srv-xxxxx  Mar-30 18:19:47  postfix  NOQUEUE: reject: RCPT from unknown[27.41.141.150]: 55...
     srv-xxxxx  Apr-04 08:27:32  postfix  NOQUEUE: reject: RCPT from unknown[27.41.145.103]: 55...
     srv-xxxxx  Mar-26 10:40:19  postfix  NOQUEUE: reject: RCPT from unknown[120.87.225.219]: 5...
     srv-xxxxx  Mar-29 20:59:40  postfix  NOQUEUE: reject: RCPT from 114-44-108-178.dynamic.hin...
     srv-xxxxx  Mar-21 13:18:02  postfix  NOQUEUE: reject: RCPT from unknown[27.41.132.80]: 554...
     srv-xxxxx  Apr-04 08:55:16  postfix  NOQUEUE: reject: RCPT from unknown[27.41.145.103]: 55...
     srv-xxxxx  Mar-29 22:41:55  postfix  NOQUEUE: reject: RCPT from unknown[112.92.104.192]: 5...
     srv-xxxxx  Mar-25 03:20:15  postfix  NOQUEUE: reject: RCPT from unknown[27.41.147.107]: 55...
     srv-xxxxx  Mar-22 23:54:32  postfix  NOQUEUE: reject: RCPT from unknown[27.41.137.164]: 55...
    -----------------------------------------------------------------------------------------------

Or exclude a search term and sort the results by their timestamp rather than by match score:

    $ riak-syslog search --timesort program:nagios3 alert NOT critical
    
     host       time             program  log                                                     
    -----------------------------------------------------------------------------------------------
     srv-dhodx  Mar-25 04:41:33  nagios3  SERVICE ALERT: srv-o25ey;ActiveMQ Poller;UNKNOWN;SOFT...
     srv-dhodx  Mar-21 15:32:10  nagios3  SERVICE ALERT: ps122;stomp_access;WARNING;SOFT;1;CHEC...
     srv-dhodx  Feb-02 21:20:56  nagios3  SERVICE ALERT: ps128;time;OK;SOFT;2;NTP OK: Offset -0...
     srv-dhodx  Jan-28 09:10:55  nagios3  SERVICE ALERT: srv-dhodx;Gearman service queue;WARNIN...
     srv-dhodx  Jan-14 11:58:17  nagios3  SERVICE ALERT: srv-dhodx;Gearman host queue;WARNING;S...
     srv-dhodx  Dec-24 12:08:20  nagios3  SERVICE ALERT: ps101;Load;WARNING;HARD;4;WARNING - lo...
     srv-dhodx  Dec-22 18:57:42  nagios3  SERVICE ALERT: srv-x5gsg;Load;OK;HARD;4;OK - load ave...
     srv-dhodx  Dec-22 18:20:12  nagios3  SERVICE ALERT: ps101;polkitd-ram;OK;HARD;4;PROCS OK: ...
     srv-dhodx  Dec-05 06:15:40  nagios3  SERVICE ALERT: srv-dhodx;Gearman eventhandler queue;W...
     srv-dhodx  Dec-04 17:03:36  nagios3  SERVICE ALERT: ps125;time;OK;SOFT;2;NTP OK: Offset 0....
    -----------------------------------------------------------------------------------------------

All the options are documented:

    $ riak-syslog help search
    search [command options] 
        search syslog messages
    
    Command Options:
        -f, --from=arg  - Limit to messages from this time (e.g: 2 days ago)
        -l, --limit=arg - number of records to return
        -r, --timesort  - sort results by timestamp
        -t, --to=arg    - Limit to messages to this time (e.g: 1 day ago)
        -y, --showyear  - Show year in timestamp

See the schema file for other fields you can search on specifically.

## Syslog daemon setup

 The following steps are for use with
`rsyslog` but any syslog daemon that can send syslog messages to a
fifo in a specific format will do.

Create a fifo somewhere. On Debian/Ubuntu
`/var/run/riak-syslog-receiver` is a good place (though it will need
creating after each boot!):

    mkfifo /var/run/riak-syslog-receiver
	chown syslog.syslog /var/run/riak-syslog-receiver 

Then configure your syslog daemon to write logs to the fifo in the
right format. For `rsyslog`:

    $template RiaklogFormat,"%FROMHOST%\9%syslogfacility-text%\9%msg%\9%HOSTNAME%\9%syslogpriority%\9%syslogtag%\9%programname%\9%syslogseverity-text%\9%timegenerated:::date-rfc3339%\n"
    *.* |/var/run/riak-syslog-receiver;RiaklogFormat

On Debian/Ubuntu, you can drop it in
`/etc/rsyslog.d/riak-syslog.conf`. Note that you need to specify the
path to your fifo.

## riak-syslog config

Specify the address of your Riak cluster, the Riak bucket name and the
protocol in `/etc/riak-syslog.yml`.  We'll assume a bucket name of
`riak-syslog`. The `pbc` protocol is recommended for performance, but
http will work just fine:

    host: localhost
    bucket: riak-syslog
    protocol: pbc
	
The search query tool will use this same config file, but it also
looks in the current directory and `~/.riak-syslog.yml` too. This
makes it a bit easier to configure it if you're running the search
tool from a node that isn't part of the riak cluster (obviously you
need to set the `host` to a Riak node.)

`protocol` can be `pbc` or `http`, depending which ports you've opened
access to.
		
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

## Receiver setup

You then need to run the `riak-syslog-receiver` daemon, which will
read syslog messages from the fifo and write them into Riak.  If
you're using upstart, it's easy to configure this to run on boot. Just
create an upstart config called `/etc/init/riak-syslog.conf` with
the contents:

    start on filesystem
    stop on runlevel [06]
    
    respawn
	
	env NAMED_PIPE=/var/run/riak-syslog-receiver
	
	pre-start script
	  test -p $NAMED_NAME || mkfifo $NAMED_PIPE
	  chown syslog.syslog $NAMED_PIPE
      chmod 640 $NAMED_PIPE
	end script
    
    exec riak-syslog-receiver

then start the daemon:

    $ start riak-syslog

# More Info

* Author: John Leach <john@johnleach.co.uk>
* Copyright: Copyright (c) 2012 John Leach
* License: MIT
* Web page: http://johnleach.co.uk/words/1063/riak-syslog
* Github: https://github.com/johnl/riak-syslog
