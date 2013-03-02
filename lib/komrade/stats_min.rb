require 'komrade/pg'
require 'komrade/stats_raw'

module KomradeApi
  module StatsMin
    extend self
    HOUR = 60*60
    QUEUE_ACTIONS = [0,1,2,3]

    def by_hour(qid, time, action, maxid)
      time = (time/HOUR) * HOUR
      s=['select sum(count) as count, max(id) as maxid,',
        "date_trunc('hour', time) as time,",
        'queue, action',
        'from stat_min',
        'where queue = ? and action = ? and id > ? and',
        "extract('epoch' from date_trunc('hour', time)) = ?",
        'group by 3, 4, 5'].join(' ')
      KomradeApi.stats_pg[s, qid, action, maxid, time].to_a
    end

    def aggregate(qid, time=Time.now.to_i)
      time = (time/HOUR) * HOUR
      s=['select time, action, sum(count) as count',
          'from stat_min',
          "where queue = ? and extract('epoch' from date_trunc('hour', time)) = ?",
          'group by 1, 2',
          'order by time asc'].join(' ')
      KomradeApi.stats_pg[s, qid, time].to_a.map do |stat|
        stat.merge(count: stat[:count].to_i)
      end
    end

    def compact(qid, t=Time.now.to_i)
      existing = get(qid, t).group_by {|s| s[:action]}
      QUEUE_ACTIONS.map do |a|
        maxid = (existing[a] && existing[a].max {|s| s[:maxid]}[:maxid]) || 0
        if raw = StatsRaw.by_min(qid, t, a, maxid).pop
          KomradeApi.stats_pg[:stat_min].returning.insert(queue: qid,
            time: raw[:time], maxid: raw[:maxid], count: raw[:count], action: a)
        end
      end
    end

    def get(qid, t)
      t = (t/HOUR) * HOUR
      s=['select * from stat_min',
        "where queue = ? and extract('epoch' from time) = ?"].join(' ')
      KomradeApi.stats_pg[s, qid, t].to_a
    end

  end
end
