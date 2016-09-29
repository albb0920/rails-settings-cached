require 'digest/md5'

module RailsSettings
  class Default < ::Hash
    class MissingKey < StandardError; end

    class << self
      def enabled?
        source_path && File.exist?(source_path)
      end

      def source(value = nil)
        @source ||= value
      end

      def source_path
        @source || Rails.root.join('config/app.yml')
      end

      def [](key)
        # foo.bar.dar Nested fetch value
        return instance[key] if instance.has_key?(key)
        keys = key.to_s.split('.')
        val = instance
        keys.each do |k|
          if val.respond_to? :fetch
            val = val.fetch(k.to_s, nil)
          else
            val = nil
          end
          break if val.nil?
        end
        val
      end

      def instance
        return @instance if defined? @instance
        @instance = new
        @instance
      end
    end

    def initialize
      content = open(self.class.source_path).read
      hash = content.empty? ? {} : YAML.load(ERB.new(content).result).to_hash
      hash = self.class.flatten_hash(hash[Rails.env] || {})
      self.replace hash
    end

    private
    def self.flatten_hash(hash)
      hash.each_with_object({}) do |(k, v), h|
        if v.is_a? Hash
          flatten_hash(v).map do |h_k, h_v|
            h["#{k}.#{h_k}"] = h_v
          end
        else
          h[k] = v
        end
      end
    end
  end
end
