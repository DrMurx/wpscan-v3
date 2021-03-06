module WPScan
  module Finders
    module DynamicFinder
      module WpItemVersion
        # Version finder using Body Pattern method. Tipically used when the response is not
        # an HTML doc and Xpath can't be used
        class BodyPattern < WPScan::Finders::DynamicFinder::WpItemVersion::Finder
          # @param [ Constant ] mod
          # @param [ Constant ] klass
          # @param [ Hash ] config
          def self.create_child_class(mod, klass, config)
            mod.const_set(
              klass, Class.new(self) do
                const_set(:PATH, config['path'])
                const_set(:PATTERN, config['pattern'])
                const_set(:CONFIDENCE, config['confidence'] || 30)
              end
            )
          end

          # @param [ Typhoeus::Response ] response
          # @param [ Hash ] opts
          # @return [ Version ]
          def find(response, _opts = {})
            return unless response.body =~ self.class::PATTERN

            WPScan::Version.new(
              Regexp.last_match[:v],
              found_by: found_by,
              confidence: self.class::CONFIDENCE,
              interesting_entries: ["#{response.effective_url}, Match: '#{Regexp.last_match}'"]
            )
          end
        end
      end
    end
  end
end
