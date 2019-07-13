class ExportMultipleClaimsService
  def initialize(supervisor: MultiplesSupervisorService)
    self.supervisor = supervisor
  end

  def call(export)
    supervisor.supervise group_name: export.dig('resource', 'reference'), count: export.dig('resource', 'secondary_claimants').length + 1
    supervisor.add_job MultipleClaimsPresenter.present(export['resource'], claimant: export['primary_claimant'], lead_claimant: true), group_name: export.dig('resource', 'reference')
  end

  private

  attr_accessor :supervisor
end
