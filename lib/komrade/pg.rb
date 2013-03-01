require 'sequel'
require 'komrade/conf'

module KomradeApi
  def self.pg
    @pg ||= Sequel.connect(Conf.database_url)
  end

  def self.stats_pg
    @stats_pg ||= Sequel.connect(Conf.stats_database_url)
  end
end
