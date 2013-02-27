require_relative 'komrade'

module KomradeApi
  module Errors
    extend self

    def get(qid)
      {
        minute: fetch(qid, 'minute'),
        hour: fetch(qid, 'hour'),
        day: fetch(qid, 'day')
      }
    end

    def fetch(qid, bucket)
      pg["select * from summarize_failed(?, ?)", qid, bucket].all.map do |r|
        payload = JSON.parse(r[:payload])
        {count: r[:count], payload: payload}
      end
    end

    def pg
      @pg ||= Sequel.connect(Conf.database_url)
    end

  end
end
