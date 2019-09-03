module EtExporter
  class ExportResponseWorker
    include Sidekiq::Worker

    def perform(json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)

    end
  end
end
