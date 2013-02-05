require 'securerandom'
require 'sequel'
require 'komrade/conf'

module Komrade
  module Queue
    extend self

    def all
      db[:queues].all
    end

    def find(id)
      db[:queues].where(token: id).where("deleted_at is null").first
    end

    def create(args)
      queue = db[:queues].returning.insert(
        heroku_id: args['heroku_id'],
        plan: args['plan'],
        callback_url: args['callback_url']
      )[0]
      {
        id: queue[:token],
        config: {'KOMRADE_URL' => queue_url(queue)},
        message: 'Komrade: working for the good of the people.'
      }
    end

    def delete(id)
      db[:queues].where(token: id).update(deleted_at: Time.now())
    end

    def change_plan(id, new_plan)
      db[:queues].where(token: id).update(plan: new_plan) == 1
    end

    def queue_url(q)
      "https://komrade:#{q[:token]}@service-1.komrade.io"
    end

    private

    def db
      @db ||= Sequel.connect(Conf.database_url)
    end

  end
end
