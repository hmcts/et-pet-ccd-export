require 'ostruct'
module EtCcdExport
  module Test
    module Json
      class Node < OpenStruct # rubocop:disable Style/OpenStructUse
        def as_json(*)
          to_h.inject({}) do |acc, (k, v)|
            acc[k.to_s] = normalize(v)
            acc
          end
        end

        private

        def normalize(value)
          case value
          when Node then value.as_json
          when Array then value.map { |i| normalize(i) }
          else value
          end
        end
      end

      class Document < Node

      end
    end

  end
end
