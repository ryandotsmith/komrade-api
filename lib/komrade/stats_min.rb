require 'komrade/pg'
require 'komrade/stats_raw'

module KomradeApi
  module StatsMin
    extend self
    QUEUE_ACTIONS = [0,1,2,3]

    def aggregate(qid, t=Time.now)
      t = (t.to_i/(60*60)) * (60*60)
      s=['select time, action, sum(count) as count',
          'from stat_min',
          "where queue = ? and extract('epoch' from date_trunc('hour', time)) = ?",
          'group by 1, 2',
          'order by time asc'].join(' ')
      KomradeApi.pg[s, qid, t].to_a
    end

    def compact(qid, t=Time.now)
      existing = get(qid, t).group_by {|s| s[:action]}
      QUEUE_ACTIONS.map do |a|
        maxid = (existing[a] && existing[a].max {|s| s[:maxid]}[:maxid]) || 0
        if raw = StatsRaw.by_min(qid, t, a, maxid).pop
          KomradeApi.pg[:stat_min].returning.insert(queue: qid,
            time: raw[:time], maxid: raw[:maxid], count: raw[:count], action: a)
        end
      end
    end

    def get(qid, t)
      t = (t.to_i/(60*60)) * (60*60)
      s=['select * from stat_min',
        "where queue = ? and extract('epoch' from time) = ?"].join(' ')
      KomradeApi.pg[s, qid, t].to_a
    end

  end
end
