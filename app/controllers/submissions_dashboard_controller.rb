# frozen_string_literal: true

class SubmissionsDashboardController < ApplicationController
  load_and_authorize_resource :submission, parent: false

  def index
    base_scope = @submissions.left_joins(:template)
                             .where(archived_at: nil)
                             .where(templates: { archived_at: nil })
                             .preload(:created_by_user, template: :author)

    @stats_total = base_scope.count
    @stats_completed = base_scope.completed.count
    @stats_awaiting = base_scope.pending.count
    @stats_avg_time = average_completion_time(base_scope)

    @submissions = Submissions.search(current_user, base_scope, params[:q], search_template: true)
    @submissions = Submissions::Filter.call(@submissions, current_user, params)

    @submissions = if params[:completed_at_from].present? || params[:completed_at_to].present?
                     @submissions.order(Submitter.arel_table[:completed_at].maximum.desc)
                   else
                     @submissions.order(id: :desc)
                   end

    @pagy, @submissions = pagy_auto(@submissions.preload(submitters: :start_form_submission_events))
  end

  private

  def average_completion_time(scope)
    adapter = ActiveRecord::Base.connection.adapter_name.to_s.downcase
    duration_sql = if adapter.include?('sqlite')
                     "(julianday(completed_at) - julianday(created_at)) * 86400.0"
                   else
                     'EXTRACT(EPOCH FROM (completed_at - created_at))'
                   end

    avg_seconds = Submitter.where(submission_id: scope.select(:id))
                           .where.not(completed_at: nil)
                           .average(Arel.sql(duration_sql))

    return '--' unless avg_seconds

    minutes = (avg_seconds.to_f / 60.0).round

    return "#{minutes}m" if minutes < 60

    hours = (minutes / 60.0).round
    "#{hours}h"
  end
end
