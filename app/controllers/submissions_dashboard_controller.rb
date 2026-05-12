# frozen_string_literal: true

class SubmissionsDashboardController < ApplicationController
  load_and_authorize_resource :submission, parent: false

  def index
    base_scope = @submissions.left_joins(:template)
                             .where(archived_at: nil)
                             .where(templates: { archived_at: nil })
                             .preload(:created_by_user, template: :author)

    filtered_scope = Submissions.search(current_user, base_scope, params[:q], search_template: true)
    filtered_scope = Submissions::Filter.call(filtered_scope, current_user, params)

    @stats_total = submission_scope_count(filtered_scope)
    @stats_completed = submission_scope_count(filtered_scope.completed)
    @stats_awaiting = submission_scope_count(filtered_scope.pending)
    @stats_avg_time = average_completion_time(filtered_scope)

    @submissions = filtered_scope

    @submissions = if params[:completed_at_from].present? || params[:completed_at_to].present?
                     @submissions.order(Submitter.arel_table[:completed_at].maximum.desc)
                   else
                     @submissions.order(id: :desc)
                   end

    @pagy, @submissions = pagy_auto(@submissions.preload(submitters: :start_form_submission_events))
  end

  private

  # Plain search and some filters use GROUP BY id; +count+ then returns a Hash.
  def submission_scope_count(scope)
    count = scope.count
    count.is_a?(Hash) ? count.size : count
  end

  def average_completion_time(scope)
    adapter = ActiveRecord::Base.connection.adapter_name.to_s.downcase
    duration_sql = if adapter.include?('sqlite')
                     '(julianday(completed_at) - julianday(created_at)) * 86400.0'
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
