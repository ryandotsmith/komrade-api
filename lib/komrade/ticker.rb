require 'komrade-client'
require 'komrade/queue'

module KomradeApi
  module Ticker
    extend self

    def start
      loop do
        t = Time.now
        process_minute(t) if t.sec % 30 == 0
        process_hour(t) if t.min % 30 == 0
        sleep(1)
      end
    end

    def process_minute(t)
      puts("at=process-minute")
      Queue.all.each do |queue|
        Komrade::Queue.enqueue("KomradeApi::StatsMin.compact", queue[:token], t.to_i)
      end
    end

    def process_hour(t)
      puts("at=process-minute")
      Queue.all.each do |queue|
        Komrade::Queue.enqueue("KomradeApi::StatsHour.compact", queue[:token], t.to_i)
      end
    end

  end
end
