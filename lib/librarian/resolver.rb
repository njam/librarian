require 'librarian/resolver/implementation'
require 'librarian/manifest_set'
require 'librarian/resolution'

module Librarian
  class Resolver

    attr_accessor :environment
    private :environment=

    def initialize(environment)
      self.environment = environment
    end

    def resolve(spec, partial_manifests = [])
      manifests = implementation(spec).resolve(partial_manifests)
      manifests or return
      enforce_consistency!(spec.dependencies, manifests)
      manifests = sort(manifests)
      Resolution.new(spec.dependencies, manifests)
    end

  private

    def implementation(spec)
      Implementation.new(self, spec)
    end

    def enforce_consistency!(dependencies, manifests)
      manifest_set = ManifestSet.new(manifests)
      return if manifest_set.in_compliance_with?(dependencies)
      return if manifest_set.consistent?

      debug { "Resolver Malfunctioned!" }
      errors = []
      dependencies.sort_by(&:name).each do |d|
        m = manifests[d.name]
        if !m
          errors << ["Depends on #{d}", "Missing!"]
        elsif !d.satisfied_by?(m)
          errors << ["Depends on #{d}", "Found: #{m}"]
        end
      end
      unless errors.empty?
        errors.each do |a, b|
          debug { "  #{a}" }
          debug { "    #{b}" }
        end
      end
      manifests.values.sort_by(&:name).each do |manifest|
        errors = []
        manifest.dependencies.sort_by(&:name).each do |d|
          m = manifests[d.name]
          if !m
            errors << ["Depends on: #{d}", "Missing!"]
          elsif !d.satisfied_by?(m)
            errors << ["Depends on: #{d}", "Found: #{m}"]
          end
        end
        unless errors.empty?
          debug { "  #{manifest}" }
          errors.each do |a, b|
            debug { "    #{a}" }
            debug { "      #{b}" }
          end
        end
      end
      raise Error, "Resolver Malfunctioned!"
    end

    def sort(manifests)
      ManifestSet.sort(manifests)
    end

    def debug(*args, &block)
      environment.logger.debug(*args, &block)
    end

  end
end
