require 'sequel'
require 'komrade/conf'

module KomradeApi
  module FailedJob
    extend self

    def in_last_three_seconds(queue_id, timestamp)
      db[:failed_jobs].where(queue: queue_id).where('created_at > ?', Time.at(timestamp-3))
    end

    private

      def db
        @db ||= Sequel.connect(Conf.database_url)
      end
  end
end
