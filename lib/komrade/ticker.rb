require 'komrade-client'

module KomradeApi
  module Ticker
    extend self

    def start
      loop do
        t = Time.now
        process_minute(t) if t.sec % 30 == 0
        sleep(1)
      end
    end

    def process_minute(t)
      puts("at=process-minute")
      Queue.all.each do |queue|
        Komrade::Queue.enqueue("KomradeApi::StatsMin.compact", queue[:token], t.to_i)
      end
    end

  end
end
