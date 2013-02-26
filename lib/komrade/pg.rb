require 'sequel'
require 'komrade/conf'

module KomradeApi
  def self.pg
    @pg ||= Sequel.connect(Conf.database_url)
  end
end
