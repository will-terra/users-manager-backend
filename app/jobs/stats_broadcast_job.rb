class StatsBroadcastJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # This job delegates to the service that builds and broadcasts
    # the administrative stats snapshot. Keeping the job thin lets
    # the service be invoked from other places (e.g. controllers)
    # and keeps test surface small.
    StatsBroadcastService.broadcast_stats_update
  end
end
