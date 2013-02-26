require 'komrade/utils'
require 'komrade/pg'

module KomradeApi
  module StatsRaw
    extend self

    def by_min(qid, t, action, maxid=0)
      t = (t.to_i/60) * 60
      s=['select count(*), max(id) as maxid,',
        " date_trunc('minute', time) as time,",
        'queue, action',
        'from metabolism_reports',
        'where queue = ? and action = ? and id > ? and',
        "extract('epoch' from date_trunc('minute', time)) = ?",
        'group by 3, 4, 5'].join(' ')
      KomradeApi.pg[s, qid, action, maxid, t].to_a
    end

  end
end
