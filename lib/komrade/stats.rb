require 'komrade/conf'
require 'komrade/utils'

module KomradeApi
  module Stats
    extend self
    ENQUEUE = 0
    DEQUEUE = 1
    DELETE = 2
    ERROR = 3

    def historical(qid, resolution, limit)
      s =  "select date_trunc('#{resolution}', time) as time, action, count(*) from metabolism_reports"
      s += " where queue = ? and time >= date_trunc('#{resolution}', now()) - '1 #{limit}'::interval and time < date_trunc('#{resolution}', now()) "
      s += "group by 1, 2 "
      s += "order by time asc"
      log(at: resolution) do
        pg[s, qid].to_a
      end
    end

    def real_time(qid)
      s =  "select now() as time, action, count(*) from metabolism_reports"
      s += " where queue = ? and time > now() - '1 minute'::interval "
      s += "group by 1, 2"
      log(at: 'real-time') do
        pg[s, qid].to_a
      end
    end

    def pg
      @pg ||= Sequel.connect(Conf.database_url)
    end

    def log(data, &blk)
      Utils.log({ns: "web"}.merge(data), &blk)
    end

  end
end
