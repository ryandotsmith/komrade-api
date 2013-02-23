module KomradeApi
  module Conf
    extend self
    def env(k)
      ENV[k]
    end

    def env!(k)
      env(k) || raise("Missing: #{k}")
    end

    def app_name; env!("APP_NAME"); end
    def database_url; env!("DATABASE_URL"); end
    def database_read_url; env!("DATABASE_READ_URL"); end
    def port; env!("PORT"); end
    def heroku_username; env!("HEROKU_USERNAME"); end
    def heroku_password; env!("HEROKU_PASSWORD"); end
    def admin_username; env!("ADMIN_USERNAME"); end
    def admin_password; env!("ADMIN_PASSWORD"); end
  end
end
