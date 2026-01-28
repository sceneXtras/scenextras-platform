# Service Health Monitor Scenario
# Run with: ./deploy.sh run-script scripts/deploy_health_monitor.rb
#
# Monitors multiple service endpoints and posts to Discord on failures

require 'json'

DISCORD_WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL'] || 'YOUR_DISCORD_WEBHOOK_URL'
ADMIN_USERNAME = ENV['HUGINN_ADMIN_USERNAME'] || 'admin'

# Services to monitor (modify as needed)
SERVICES = [
  { name: 'API', url: 'https://api.scenextras.com/healthcheck/ready', expected: 'ready' },
  { name: 'Search', url: 'https://api.scenextras.com/search/health', expected: 'ok' },
  { name: 'Gateway', url: 'https://api.scenextras.com/gateway/health', expected: 'ok' },
  { name: 'LogWard', url: 'https://logging.scenextras.com/health', expected: 'ok' }
]

puts "Deploying Health Monitor..."

user = User.find_by(username: ADMIN_USERNAME)
unless user
  puts "ERROR: User '#{ADMIN_USERNAME}' not found"
  exit 1
end

# Clean up
user.agents.where("name LIKE 'Health Monitor%' OR name LIKE 'Service Down Alert%'").destroy_all
puts "Cleaned up existing agents"

discord_poster = nil
all_monitors = []

# Create Discord alert poster (shared)
discord_poster = user.agents.create!(
  name: 'Service Down Alert - Discord',
  type: 'Agents::PostAgent',
  schedule: 'never',
  keep_events_for: 604800,
  options: {
    'post_url' => DISCORD_WEBHOOK_URL,
    'expected_receive_period_in_days' => 1,
    'content_type' => 'json',
    'method' => 'post',
    'payload' => {
      'embeds' => [
        {
          'title' => '🚨 SERVICE DOWN',
          'description' => '**{{ service_name }}** is not responding!',
          'color' => 15158332,
          'fields' => [
            { 'name' => 'URL', 'value' => '{{ url }}', 'inline' => false },
            { 'name' => 'Status', 'value' => '{{ status }}', 'inline' => true },
            { 'name' => 'Expected', 'value' => '{{ expected }}', 'inline' => true }
          ],
          'timestamp' => '{{ timestamp }}'
        }
      ]
    }.to_json,
    'headers' => { 'Content-Type' => 'application/json' }
  }
)
puts "Created: #{discord_poster.name}"

# Create monitor for each service
SERVICES.each do |service|
  # HTTP checker
  checker = user.agents.create!(
    name: "Health Monitor - #{service[:name]}",
    type: 'Agents::HttpStatusAgent',
    schedule: 'every_5m',
    keep_events_for: 86400,
    options: {
      'url' => service[:url],
      'headers_to_save' => '',
      'expected_receive_period_in_days' => 1
    }
  )
  puts "Created: #{checker.name}"

  # Trigger agent (fires on failure)
  trigger = user.agents.create!(
    name: "Health Monitor Trigger - #{service[:name]}",
    type: 'Agents::TriggerAgent',
    schedule: 'never',
    keep_events_for: 86400,
    options: {
      'expected_receive_period_in_days' => 1,
      'keep_event' => 'false',
      'rules' => [
        {
          'type' => 'field!=value',
          'value' => '200',
          'path' => '$.status'
        }
      ],
      'message' => {
        'service_name' => service[:name],
        'url' => service[:url],
        'status' => '{{ status }}',
        'expected' => service[:expected],
        'timestamp' => '{{ _time_ }}'
      }.to_json
    }
  )
  puts "Created: #{trigger.name}"

  # Link: Checker -> Trigger -> Discord
  checker.links_as_source.create!(receiver: trigger)
  trigger.links_as_source.create!(receiver: discord_poster)
  puts "Linked: #{checker.name} -> #{trigger.name} -> #{discord_poster.name}"
end

puts ""
puts "=" * 60
puts "HEALTH MONITOR DEPLOYMENT COMPLETE"
puts "=" * 60
puts ""
puts "Monitoring #{SERVICES.length} services every 5 minutes"
puts "Alerts will be posted to Discord on any non-200 response"
puts ""
puts "IMPORTANT: Update DISCORD_WEBHOOK_URL before running!"
puts "=" * 60
