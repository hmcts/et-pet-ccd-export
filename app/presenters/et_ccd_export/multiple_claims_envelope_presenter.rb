module EtCcdExport
  class MultipleClaimsEnvelopePresenter
    def self.present(data, event_token:)
      <<-JSON
      {
          "data": #{data},
          "event": {
            "id": "initiateCase",
            "summary": "",
            "description": ""
          },
          "event_token": "#{event_token}",
          "ignore_warning": false,
          "draft_id": null
      }

      JSON
    end
  end
end
