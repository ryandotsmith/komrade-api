require 'komrade/pg'
require 'komrade/stats_min'

module KomradeApi
  module StatsHour
    extend self
    DAY = 60*60*24
    QUEUE_ACTIONS = [0,1,2,3]

    def aggregate(qid, time=Time.now.to_i)
      time = (time/DAY)*DAY
      s=['select time, action, sum(count) as count',
          'from stat_hour',
          "where queue = ? and extract('epoch' from date_trunc('day', time)) = ?",
          'group by 1, 2',
          'order by time asc'].join(' ')
      KomradeApi.pg[s, qid, time].to_a
    end

    def compact(qid, t=Time.now.to_i)
      existing = get(qid, t).group_by {|s| s[:action]}
      QUEUE_ACTIONS.map do |a|
        maxid = (existing[a] && existing[a].max {|s| s[:maxid]}[:maxid]) || 0
        if raw = StatsMin.by_hour(qid, t, a, maxid).pop
          KomradeApi.pg[:stat_hour].returning.insert(queue: qid,
            time: raw[:time], maxid: raw[:maxid], count: raw[:count], action: a)
        end
      end
    end

    def get(qid, t)
      t = (t/DAY)*DAY
      s=['select * from stat_hour',
        "where queue = ? and extract('epoch' from time) = ?"].join(' ')
      KomradeApi.pg[s, qid, t].to_a
    end

  end
end
