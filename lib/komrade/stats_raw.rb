require 'komrade/utils'
require 'komrade/pg'

module KomradeApi
  module StatsRaw
    extend self

    def by_min(qid, time, action, maxid=0)
      time = (time/60) * 60
      s=['select count(*), max(id) as maxid,',
        "date_trunc('minute', time) as time,",
        'queue, action',
        'from stat_raw',
        'where queue = ? and action = ? and id > ? and',
        "extract('epoch' from date_trunc('minute', time)) = ?",
        'group by 3, 4, 5'].join(' ')
      KomradeApi.stats_pg[s, qid, action, maxid, time].to_a
    end

    def aggregate(qid, limit=1)
      s=['select now() as time, action, count(*)',
        'from stat_raw',
        "where queue = ? and time >= now() - '#{limit} seconds'::interval",
        'group by 1, 2'].join(' ')
      KomradeApi.stats_pg[s, qid].to_a
    end

  end
end
