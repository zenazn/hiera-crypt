require 'hiera/config'

class Hiera
  module Backend
    class Crypt_backend
      DEBUG_PREFIX = '[crypt backend]'

      def initialize(cache=nil)
        unless conf = Hiera::Config.include?(:crypt)
          raise "Expected :crypt section in hiera.yaml"
        end
        unless conf.include?(:password) || conf.include?(:password_file)
        end
        password = if conf.include?(:password)
          conf[:password]
        elsif conf.include?(:password_file)
          debug("Reading password from #{conf[:password_file]}")
          password_file = File.expand_path(conf[:password_file])
          File.open(password_file, 'r').read.chomp
        else
          raise "Expected either a :password or :password_file"
        end

        require 'gpgme'
        @crypto = GPGME::Crypto.new(:password => password)

        @cache = cache || FileCache.new
        debug("Loaded!")
      end

      def lookup(key, scope, order_override, resolution_type)
        unless [:array, :priority].include?(resolution_type)
          raise "Unsupported resolution type #{resolution_type.inspect}"
        end

        debug("Looking up #{key}")

        answers = []
        Backend.datasources(scope, order_override) do |source|
          debug("Looking for data source #{source}")

          file = File.join([datadir(:crypto, scope), source, "#{key}.gpg"])
          next unless File.exist?(file)

          plaintext = @cache.read(file, String, "") do |data|
            decrypt(data)
          end

          return plaintext if resolution_type == :priority

          answers << plaintext
        end
        answers
      end

      private
      def decrypt(file)
        @crypto.decrypt(file)
      end

      def debug(msg)
        Hiera.debug("#{DEBUG_PREFIX} #{msg}")
      end
    end
  end
end
