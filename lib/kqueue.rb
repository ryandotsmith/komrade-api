require 'securerandom'
require 'conf'
require 'sequel'

module KQueue
  extend self

  def find(id)
    db[:queues].where(token: id).first
  end

  def create(args)
    queue = db[:queues].returning.insert(
      heroku_id: args['heroku_id'],
      plan: args['plan'],
      callback_url: args['callback_url']
    )[0]
    puts queue
    {
      id: queue[:token],
      config: {'KOMRADE_URL' => queue_url(queue)},
      message: 'Komrade: working for the good of the people.'
    }
  end

  def delete(id)
    db[:queues].where(id: id).delete == 1
  end

  def change_plan(id, new_plan)
    db[:queues].where(id: id).update(plan: new_plan) == 1
  end

  def queue_url(q)
    "http://komrade:#{q[:token]}@service-1.komrade.32k.io"
  end

  private

  def db
    @db ||= Sequel.connect(Conf.database_url)
  end

end
