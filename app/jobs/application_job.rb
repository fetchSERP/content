class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
  def broadcast_credit(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      "streaming_channel_#{user.id}",
      target: "user_credit",
      partial: "shared/user_credit",
      locals: { user: user }
    )
  end
end
