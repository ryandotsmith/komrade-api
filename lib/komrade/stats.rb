require 'komrade/conf'

module Komrade
  module Stats
    extend self
    ENQUEUE = 0
    DELETE = 2

    def all(queue_id)
      {
        in: _in(queue_id),
        out: out(queue_id),
        error: error(queue_id),
        lost: lost_jobs(queue_id)
      }
    end

    def _in(queue_id)
      {
        minute: metabolism(queue_id, ENQUEUE, 'minute'),
        hour: metabolism(queue_id, ENQUEUE, 'hour'),
        day: metabolism(queue_id, ENQUEUE, 'day')
      }
    end

    def out(queue_id)
      {
        minute: metabolism(queue_id, DELETE, 'minute'),
        hour: metabolism(queue_id, DELETE, 'hour'),
        day: metabolism(queue_id, DELETE, 'day')
      }
    end

    def lost(queue_id)
      {
        minute: lost_jobs(queue_id, 'minute'),
        hour: lost_jobs(queue_id, 'hour'),
        day: lost_jobs(queue_id, 'day')
      }
    end

    def error(queue_id)
      {
        minute: failed_jobs(queue_id, 'minute'),
        hour: failed_jobs(queue_id, 'hour'),
        day: failed_jobs(queue_id, 'day')
      }
    end

    def lost_jobs(qid, period)
      pg[:jobs].
        where(queue: qid).
        where("locked_at is not null").
        where("failed_at = 0").
        where("heartbeat - now() < '1 #{period}'::interval").
        count
    end

    def failed_jobs(qid, period)
      pg[:failed_jobs].
        where(queue: qid).
        where("created_at > now() - '1 #{period}'::interval").
        count
    end

    def metabolism(qid, action, period)
      pg[:metabolism_reports].
        where(queue: qid, action: action).
        where("time > now() - '1 #{period}'::interval").
        count
    end

    def pg
      @pg ||= Sequel.connect(Conf.database_url)
    end

  end
end
