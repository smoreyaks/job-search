class TrackingController < ApplicationController
  # Tracking's own fields, plus joe_status for the mark-as-dead toggle (it's
  # written to the row's job listing; see UpdateTrackingEntry).
  EDITABLE = Domain::TrackingFieldSanitizer::EDITABLE_FIELDS + [:joe_status]

  # GET /tracking
  def index
    render_collection(Container.list_tracking_entries.call)
  end

  # PATCH /tracking/rowSave  { id:, changed_fields: {...} }
  def row_save
    entry = Container.update_tracking_entry.call(
      id: params.require(:id),
      changed_fields: changed_fields(params)
    )
    render_entity(entry)
  end

  # PATCH /tracking/saveAll  { changes: [ { id:, changed_fields: {...} } ] }
  def save_all
    changes = params.permit(changes: [:id, { changed_fields: EDITABLE }])
                    .fetch(:changes, [])
                    .map { |change| { id: change[:id], changed_fields: (change[:changed_fields] || {}).to_h.symbolize_keys } }

    render_collection(Container.bulk_update_tracking_entries.call(changes: changes))
  end

  private

  def changed_fields(scope)
    scope.permit(changed_fields: EDITABLE).fetch(:changed_fields, {}).to_h.symbolize_keys
  end
end
