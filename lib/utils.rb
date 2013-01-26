require 'conf'

module Utils
  extend self

  def measure_t(n, t)
    n = [Conf.app_name, n].join(".")
    log(measure: n, val: t)
  end

  def log(data)
    result = nil
    if data.key?(:measure)
      data[:measure].insert(0, Conf.app_name + ".")
    end
    if block_given?
      start = Time.now
      result = yield
      data.merge!(val: (Time.now - start))
    end
    data.reduce(out=String.new) do |s, tup|
      s << [tup.first, tup.last].join("=") << " "
    end
    $stdout.puts(out)
    return result
  end

end
