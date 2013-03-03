require 'komrade/conf'
require 'komrade/pg'

module KomradeApi
  module FailedJob
    extend self

    def aggregate(qid, period=nil)
      period ||= 'hour'
      s=['select job_id, first(job_payload) as payload, max(created_at) as last_created_at, count(*)',
        'from failed_jobs',
        'where queue = ?',
        "and created_at > now() - '1 #{period}'::interval",
        'group by 1'].join(' ')
      KomradeApi.pg[s, qid].to_a.map do |j|
        payload = JSON.parse(j[:payload])
        j.merge(method: payload["method"], args: payload["args"])
      end
    end

    def by_job(jid)
      s=['select created_at, payload',
        'from failed_jobs',
        'where job_id = ?'].join(' ')
      KomradeApi.pg[s, jid].to_a
    end

  end
end
