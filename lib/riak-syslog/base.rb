module Riaksyslog

  class Record
    @@attr_names = [:key, :from, :facility, :msg, :hostname, :priority, :tag, :program, :severity, :timestamp]

    @@attr_names.each do |k|
      attr_accessor k
    end

    def initialize(a = {})
      @@attr_names.each do |k|
        send("#{k}=", a[k])
      end 
    end

    def attributes
      a = {}
      (@@attr_names - [:key]).each do |k|
        a[k] = send(k)
      end
      a
    end

    def timestamp_i
      timestamp.to_i rescue nil
    end

    def riak_object
      o = Riak::RObject.new(Record.bucket)
      o.content_type = "application/json"
      o.data = attributes
      o.indexes = { "timestamp_int" => Set.new([timestamp_i]) }
      o
    end

    def save
      o = riak_object
      if o.store
        self.key = o.key
        true
      else
        false
      end
    end

    def self.client
      @client ||= Riak::Client.new(@config)
    end

    def self.bucket
      @bucket ||= client.bucket(@bucket_name)
    end

    def self.config=(config)
      @client = nil
      @bucket = nil
      @config = config.symbolize_keys
      @bucket_name = @config.delete(:bucket)
    end

    def self.all_for(n, type = nil)
      job = Riak::MapReduce.new(client)
      job.index(@bucket_name, "name_bin", n)
      job.map "function(v){ return [v]; }", :keep => true
      job.run do |a,r| 
        Riak::RObject.load_from_mapreduce(client, r).each do |o|
          r = Record.new o.data.symbolize_keys
          r.key = o.key
          yield r
        end
      end
    end

    def self.search(q, opts = {})
      r = client.search(@bucket_name, q, opts)
      r['response']['docs'].collect do |d|
        Record.new(d["fields"].symbolize_keys)
      end
    end

  end
end
