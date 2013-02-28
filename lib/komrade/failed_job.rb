require 'sequel'
require 'komrade/conf'

module KomradeApi
  module FailedJob
    extend self

    def from(queue_id, timestamp)
      db[:failed_jobs].where(queue: queue_id).where('created_at > ?', Time.at(timestamp))
    end

    private

      def db
        @db ||= Sequel.connect(Conf.database_url)
      end
  end
end
