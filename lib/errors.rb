require 'json'
require 'sequel'
require 'conf'

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
    r = pg["select * from summarize_failed(?, ?)", qid, bucket].first
    {r[:count] => JSON.parse(r[:payload]).to_s}
  end

  def pg
    @pg ||= Sequel.connect(Conf.database_url)
  end

end
