module WPScan
  module Finders
    module DynamicFinder
      module WpItemVersion
        # Version finder using JavaScript Variable method
        class JavascriptVar < WPScan::Finders::DynamicFinder::WpItemVersion::Finder
          # @param [ Constant ] mod
          # @param [ Constant ] klass
          # @param [ Hash ] config
          def self.create_child_class(mod, klass, config)
            mod.const_set(
              klass, Class.new(self) do
                const_set(:PATH, config['path'])
                const_set(:XPATH, config['xpath'] || '//script[not(@src)]')
                const_set(:PATTERN, config['pattern'])
                const_set(:CONFIDENCE, config['confidence'] || 60)
                const_set(:VERSION_KEY, config['version_key'])
              end
            )
          end

          # @param [ Typhoeus::Response ] response
          # @param [ Hash ] opts
          # @return [ Version ]
          def find(response, _opts = {})
            # target is the item (plugin/theme)
            # target.target is the WP blog
            target.target.xpath_pattern_from_page(
              self.class::XPATH, self.class::PATTERN, response
            ) do |match_data, _node|
              next unless (version_number = version_number_from_match_data(match_data))

              # If the text to be output in the interesting_entries is > 50 chars,
              # get 20 chars before and after (when possible) the detected version instead
              match = match_data.to_s

              if match.size > 50
                match = match[/.*?(.{,20}#{Regexp.escape(version_number)}.{,20}).*/, 1]
              end

              return WPScan::Version.new(
                version_number,
                found_by: found_by,
                confidence: self.class::CONFIDENCE,
                interesting_entries: ["#{response.effective_url}, Match: '#{match}'"]
              )
            end
            nil
          end

          # @param [ MatchData ] match_data
          # @return [ String ]
          def version_number_from_match_data(match_data)
            if self.class::VERSION_KEY
              begin
                json = JSON.parse("{#{match_data[:json]}}")
              rescue JSON::ParserError
                return
              end

              json.dig(*self.class::VERSION_KEY.split(':'))
            else
              match_data[:v]
            end
          end
        end
      end
    end
  end
end
