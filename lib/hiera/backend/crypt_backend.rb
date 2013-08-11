require 'hiera/config'

class Hiera
  module Backend
    class Crypt_backend
      DEBUG_PREFIX = '[crypt backend]'

      def initialize()
        unless Hiera::Config.include?(:crypt)
          raise "Expected :crypt section in hiera.yaml"
        end
        conf = Hiera::Config[:crypt]
        password = if conf.include?(:password)
          conf[:password]
        elsif conf.include?(:password_file)
          debug("Reading password from #{conf[:password_file]}")
          password_file = File.expand_path(conf[:password_file])
          File.open(password_file, 'r').read.chomp
        else
          raise "Expected either a :password or :password_file"
        end

        @cache = {}

        require 'gpgme'
        @crypto = GPGME::Crypto.new(:password => password)
        debug("Loaded!")
      end

      def lookup(key, scope, order_override, resolution_type)
        unless [:array, :priority].include?(resolution_type)
          raise "Unsupported resolution type #{resolution_type.inspect}"
        end

        debug("Looking up #{key}")

        answers = nil
        Backend.datasources(scope, order_override) do |source|
          debug("Looking for data source #{source}")

          file = File.join(Backend.datadir(:crypt, scope), source, "#{key}.gpg")
          debug("Examining file #{file}")
          next unless File.exist?(file)

          plaintext = decrypt(file)

          return plaintext if resolution_type == :priority

          answers ||= []
          answers << plaintext
        end
        answers
      end

      private
      def decrypt(file)
        stat = File.stat(f = File.new(file))
        info = {:inode => stat.ino, :mtime => stat.mtime, :size => stat.size}
        @cache.delete(file) if @cache[file] && @cache[file][:info] != info

        debug("Using cached value for #{file}") if @cache.include?(file)

        @cache[file] ||= {
          :contents => @crypto.decrypt(f).to_s,
          :info => info
        }

        @cache[file][:contents]
      end

      def debug(msg)
        Hiera.debug("#{DEBUG_PREFIX} #{msg}")
      end
    end
  end
end
