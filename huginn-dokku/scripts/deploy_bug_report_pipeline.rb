# Bug Report Pipeline: Bug Report Service -> Linear Ticket + Discord Notification
# Run with: LINEAR_API_KEY=xxx ./deploy.sh run-script scripts/deploy_bug_report_pipeline.rb
#
# Creates:
# 1. Webhook receiver for bug reports
# 2. Linear ticket creator
# 3. Discord notifier

require 'json'
require 'securerandom'

# Configuration
LINEAR_API_KEY = ENV['LINEAR_API_KEY'] || raise("LINEAR_API_KEY required")
LINEAR_TEAM_ID = ENV['LINEAR_TEAM_ID'] || 'ea32dd92-d7ac-40f6-bcac-eacbcd72442c'
DISCORD_WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL'] || 'https://discord.com/api/webhooks/1456249665266909281/krMsTJ4Sgbsyz5HTb93xZfvY3QvtRZVhXBbbow_Eu3HgowBkncPNrdyEZBbWfRp-sFzN'
ADMIN_USERNAME = ENV['HUGINN_ADMIN_USERNAME'] || 'admin'

# Linear Label ID Map - populated by scripts/setup_linear_labels.sh
# Format: "label:name" => "linear-label-uuid"
LINEAR_LABEL_IDS = {
  # Platform labels (blue)
  "platform:ios" => ENV['LINEAR_LABEL_PLATFORM_IOS'] || '',
  "platform:android" => ENV['LINEAR_LABEL_PLATFORM_ANDROID'] || '',
  "platform:web" => ENV['LINEAR_LABEL_PLATFORM_WEB'] || '',
  # OS labels (green)
  "os:iOS" => ENV['LINEAR_LABEL_OS_IOS'] || '',
  "os:Android" => ENV['LINEAR_LABEL_OS_ANDROID'] || '',
  "os:macOS" => ENV['LINEAR_LABEL_OS_MACOS'] || '',
  "os:Windows" => ENV['LINEAR_LABEL_OS_WINDOWS'] || '',
  "os:Linux" => ENV['LINEAR_LABEL_OS_LINUX'] || '',
  # Severity labels (red/orange/yellow/gray)
  "severity:critical" => ENV['LINEAR_LABEL_SEVERITY_CRITICAL'] || '',
  "severity:high" => ENV['LINEAR_LABEL_SEVERITY_HIGH'] || '',
  "severity:medium" => ENV['LINEAR_LABEL_SEVERITY_MEDIUM'] || '',
  "severity:low" => ENV['LINEAR_LABEL_SEVERITY_LOW'] || '',
  # Tier labels (pink)
  "tier:free" => ENV['LINEAR_LABEL_TIER_FREE'] || '',
  "tier:max" => ENV['LINEAR_LABEL_TIER_MAX'] || '',
  "tier:pro" => ENV['LINEAR_LABEL_TIER_PRO'] || '',
  "tier:creator" => ENV['LINEAR_LABEL_TIER_CREATOR'] || '',
}.freeze

puts "Deploying Bug Report Pipeline..."
puts "  Linear Team: #{LINEAR_TEAM_ID}"
puts "  Discord: #{DISCORD_WEBHOOK_URL[0..50]}..."

# Find user
user = User.find_by(username: ADMIN_USERNAME)
unless user
  puts "ERROR: User '#{ADMIN_USERNAME}' not found"
  exit 1
end

# Clean up existing agents (idempotent)
existing_names = [
  'Bug Report Webhook Receiver',
  'Bug Report Formatter',
  'Bug Report Linear Creator',
  'Bug Report Discord Notifier'
]
user.agents.where(name: existing_names).destroy_all
puts "Cleaned up existing agents"

# =============================================================================
# 1. Webhook Receiver - receives POST from bug-report service
# =============================================================================
webhook_secret = SecureRandom.hex(20)
webhook_receiver = user.agents.create!(
  name: 'Bug Report Webhook Receiver',
  type: 'Agents::WebhookAgent',
  schedule: 'never',
  keep_events_for: 2592000, # 30 days
  options: {
    'secret' => webhook_secret,
    'expected_receive_period_in_days' => 7,
    'payload_path' => '.'
  }
)
puts "Created: #{webhook_receiver.name}"

# =============================================================================
# 2. Formatter - transforms bug report into Linear/Discord format
# =============================================================================
formatter_code = <<~JS
  Agent.receive = function() {
    var agent = this;
    var events = this.incomingEvents();

    // Label ID map from environment (populated by setup script)
    var labelIdMap = #{LINEAR_LABEL_IDS.to_json};

    events.forEach(function(event) {
      var report = event.payload;
      var labels = report.labels || {};

      // Build description for Linear
      var description = [];
      description.push("## Description");
      description.push(report.description || "No description provided");
      description.push("");

      if (report.stepsToReproduce) {
        description.push("## Steps to Reproduce");
        description.push(report.stepsToReproduce);
        description.push("");
      }

      description.push("## Device Info");
      if (report.deviceInfo) {
        description.push("- **Platform:** " + (report.deviceInfo.platform || "Unknown"));
        description.push("- **OS:** " + (report.deviceInfo.os || "Unknown") + " " + (report.deviceInfo.osVersion || ""));
        description.push("- **App Version:** " + (report.deviceInfo.appVersion || "Unknown"));
        description.push("- **Device:** " + (report.deviceInfo.deviceModel || "Unknown"));
      }
      description.push("");

      description.push("## Context");
      description.push("- **Route:** " + (report.currentRoute || "Unknown"));
      if (report.navigationHistory && report.navigationHistory.length > 0) {
        description.push("- **Navigation:** " + report.navigationHistory.slice(-5).join(" -> "));
      }
      description.push("");

      if (report.userInfo) {
        description.push("## User");
        description.push("- **ID:** " + (report.userInfo.userId || "Anonymous"));
        if (report.userInfo.email) {
          description.push("- **Email:** " + report.userInfo.email);
        }
        if (report.userInfo.tier) {
          description.push("- **Tier:** " + report.userInfo.tier);
        }
        description.push("");
      }

      // Add labels section
      if (labels.platform || labels.os || labels.severity || labels.userTier) {
        description.push("## Labels");
        if (labels.platform) description.push("- **Platform:** " + labels.platform);
        if (labels.os) description.push("- **OS:** " + labels.os);
        if (labels.routeDomain) description.push("- **Route:** " + labels.routeDomain);
        if (labels.severity) description.push("- **Severity:** " + labels.severity);
        if (labels.userTier) description.push("- **Tier:** " + labels.userTier);
        description.push("");
      }

      if (report.screenshotUrl) {
        description.push("## Screenshot");
        description.push("![Screenshot](" + report.screenshotUrl + ")");
        description.push("");
      }

      description.push("---");
      description.push("**[View Full Report](https://bug-report.scenextras.com/inspector/" + report.id + ")**");
      description.push("");
      description.push("*Report ID: " + report.id + "*");
      if (report.traceId) {
        description.push("*Trace ID: " + report.traceId + "*");
      }

      // Priority based on computed severity or keywords
      var priority = 3; // Default: Normal
      var severity = labels.severity || "";
      if (severity === "critical") {
        priority = 1; // Urgent
      } else if (severity === "high") {
        priority = 2; // High
      } else if (severity === "low") {
        priority = 4; // Low
      }

      // Determine emoji for Discord based on severity
      var emoji = "🐛";
      if (severity === "critical") emoji = "🚨";
      else if (severity === "high") emoji = "⚠️";
      else if (severity === "low") emoji = "💡";

      // Resolve label names to Linear label IDs
      var labelIds = [];
      var labelNames = [];

      // Platform label
      if (labels.platform && labels.platform !== "unknown") {
        var platformKey = "platform:" + labels.platform;
        labelNames.push(platformKey);
        if (labelIdMap[platformKey]) labelIds.push(labelIdMap[platformKey]);
      }

      // OS label
      if (labels.os && labels.os !== "Unknown") {
        var osKey = "os:" + labels.os;
        labelNames.push(osKey);
        if (labelIdMap[osKey]) labelIds.push(labelIdMap[osKey]);
      }

      // Severity label
      if (labels.severity) {
        var severityKey = "severity:" + labels.severity;
        labelNames.push(severityKey);
        if (labelIdMap[severityKey]) labelIds.push(labelIdMap[severityKey]);
      }

      // Tier label
      if (labels.userTier) {
        var tierKey = "tier:" + labels.userTier;
        labelNames.push(tierKey);
        if (labelIdMap[tierKey]) labelIds.push(labelIdMap[tierKey]);
      }

      // Route labels are dynamic, not pre-created
      if (labels.routeDomain && labels.routeDomain !== "unknown") {
        labelNames.push("route:" + labels.routeDomain);
      }

      // User email labels are dynamic, not pre-created
      if (labels.userEmail) {
        labelNames.push("user:" + labels.userEmail);
      }

      // Filter out empty label IDs
      labelIds = labelIds.filter(function(id) { return id && id.length > 0; });

      // Build the complete GraphQL mutation with proper JSON
      var linearTitle = "[Bug] " + (report.title || "Bug Report");
      var linearDescription = description.join("\\n");
      var teamId = "ea32dd92-d7ac-40f6-bcac-eacbcd72442c";

      // Build mutation - include labelIds only if we have them
      var mutation;
      var variables;
      if (labelIds.length > 0) {
        mutation = "mutation CreateIssue($title: String!, $description: String!, $teamId: String!, $labelIds: [String!]) { issueCreate(input: { title: $title, description: $description, teamId: $teamId, labelIds: $labelIds }) { success issue { id identifier url labels { nodes { id name } } } } }";
        variables = {
          title: linearTitle,
          description: linearDescription,
          teamId: teamId,
          labelIds: labelIds
        };
      } else {
        mutation = "mutation CreateIssue($title: String!, $description: String!, $teamId: String!) { issueCreate(input: { title: $title, description: $description, teamId: $teamId }) { success issue { id identifier url } } }";
        variables = {
          title: linearTitle,
          description: linearDescription,
          teamId: teamId
        };
      }

      // Complete GraphQL body as JSON string
      var linearGraphqlBody = JSON.stringify({
        query: mutation,
        variables: variables
      });

      // Base64 encode for safe shell transport
      var linearGraphqlBodyB64 = '';
      try {
        // Huginn's JS engine may not have btoa, use manual base64
        var b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        var bytes = [];
        for (var i = 0; i < linearGraphqlBody.length; i++) {
          bytes.push(linearGraphqlBody.charCodeAt(i));
        }
        for (var i = 0; i < bytes.length; i += 3) {
          var b1 = bytes[i] || 0;
          var b2 = bytes[i+1] || 0;
          var b3 = bytes[i+2] || 0;
          linearGraphqlBodyB64 += b64chars[(b1 >> 2)];
          linearGraphqlBodyB64 += b64chars[((b1 & 3) << 4) | (b2 >> 4)];
          linearGraphqlBodyB64 += (i+1 < bytes.length) ? b64chars[((b2 & 15) << 2) | (b3 >> 6)] : '=';
          linearGraphqlBodyB64 += (i+2 < bytes.length) ? b64chars[b3 & 63] : '=';
        }
      } catch(e) {
        linearGraphqlBodyB64 = '';
      }

      agent.createEvent({
        // Original data
        report_id: report.id,
        title: report.title || "Bug Report",
        description_raw: report.description,
        platform: labels.platform || (report.deviceInfo ? report.deviceInfo.platform : "Unknown"),
        os: labels.os || "Unknown",
        app_version: report.deviceInfo ? report.deviceInfo.appVersion : "Unknown",
        current_route: report.currentRoute,
        route_domain: labels.routeDomain || "unknown",
        user_id: report.userInfo ? report.userInfo.userId : null,
        user_email: labels.userEmail || null,
        user_tier: labels.userTier || null,
        screenshot_url: report.screenshotUrl,
        trace_id: report.traceId,
        severity: labels.severity || "medium",

        // Formatted for Linear - complete GraphQL body (raw and base64 encoded)
        linear_graphql_body: linearGraphqlBody,
        linear_graphql_body_b64: linearGraphqlBodyB64,
        linear_title: linearTitle,
        linear_description: linearDescription,
        linear_priority: priority,
        linear_label_ids: labelIds,
        linear_label_names: labelNames,

        // For Discord
        emoji: emoji,
        priority_label: priority === 1 ? "Urgent" : (priority === 2 ? "High" : (priority === 4 ? "Low" : "Normal")),
        timestamp: new Date().toISOString()
      });
    });
  }
JS

formatter = user.agents.create!(
  name: 'Bug Report Formatter',
  type: 'Agents::JavaScriptAgent',
  schedule: 'never',
  keep_events_for: 2592000,
  options: {
    'language' => 'JavaScript',
    'code' => formatter_code,
    'expected_receive_period_in_days' => 7
  }
)
puts "Created: #{formatter.name}"

# =============================================================================
# 3. Linear Ticket Creator - uses ShellCommandAgent for HTTP request
# =============================================================================
# PostAgent doesn't support raw string payloads, and JavaScript agent lacks HTTP.
# We use ShellCommandAgent to run curl with the pre-built JSON body.
# The formatter outputs linear_graphql_body as a complete JSON string.
linear_creator = user.agents.create!(
  name: 'Bug Report Linear Creator',
  type: 'Agents::ShellCommandAgent',
  schedule: 'never',
  keep_events_for: 2592000,
  options: {
    'path' => '/usr/bin',
    'command' => "echo '{{ linear_graphql_body_b64 }}' | base64 -d | curl -s -X POST https://api.linear.app/graphql -H 'Content-Type: application/json' -H 'Authorization: #{LINEAR_API_KEY}' -d @-",
    'expected_update_period_in_days' => 7,
    'unbundle' => 'false',
    'suppress_on_failure' => 'false',
    'suppress_on_empty_output' => 'false'
  }
)
puts "Created: #{linear_creator.name}"

# =============================================================================
# 4. Discord Notifier
# =============================================================================
discord_notifier = user.agents.create!(
  name: 'Bug Report Discord Notifier',
  type: 'Agents::PostAgent',
  schedule: 'never',
  keep_events_for: 2592000,
  options: {
    'post_url' => DISCORD_WEBHOOK_URL,
    'expected_receive_period_in_days' => 7,
    'content_type' => 'json',
    'method' => 'post',
    'payload' => {
      'embeds' => [
        {
          'title' => '{{ emoji }} Bug Report: {{ title }}',
          'description' => '{{ description_raw }}',
          'color' => 15158332,
          'fields' => [
            { 'name' => 'Severity', 'value' => '{{ severity }}', 'inline' => true },
            { 'name' => 'Platform', 'value' => '{{ platform }}', 'inline' => true },
            { 'name' => 'OS', 'value' => '{{ os }}', 'inline' => true },
            { 'name' => 'App Version', 'value' => '{{ app_version }}', 'inline' => true },
            { 'name' => 'Route', 'value' => '`{{ route_domain }}`', 'inline' => true },
            { 'name' => 'User Tier', 'value' => '{{ user_tier | default: "unknown" }}', 'inline' => true },
            { 'name' => 'User Email', 'value' => '{{ user_email | default: "anonymous" }}', 'inline' => false },
            { 'name' => 'Labels', 'value' => '{{ linear_label_names | join: ", " }}', 'inline' => false }
          ],
          'footer' => {
            'text' => 'Report ID: {{ report_id }}'
          },
          'timestamp' => '{{ timestamp }}'
        }
      ]
    },
    'headers' => {
      'Content-Type' => 'application/json'
    },
    'no_merge' => 'true'
  }
)
puts "Created: #{discord_notifier.name}"

# =============================================================================
# Link Agents
# =============================================================================
# Webhook -> Formatter
webhook_receiver.links_as_source.create!(receiver: formatter)
puts "Linked: #{webhook_receiver.name} -> #{formatter.name}"

# Formatter -> Linear (parallel)
formatter.links_as_source.create!(receiver: linear_creator)
puts "Linked: #{formatter.name} -> #{linear_creator.name}"

# Formatter -> Discord (parallel)
formatter.links_as_source.create!(receiver: discord_notifier)
puts "Linked: #{formatter.name} -> #{discord_notifier.name}"

# =============================================================================
# Output
# =============================================================================
webhook_url = "https://huginn.scenextras.com/users/#{user.id}/web_requests/#{webhook_receiver.id}/#{webhook_secret}"

puts ""
puts "=" * 70
puts "BUG REPORT PIPELINE DEPLOYED"
puts "=" * 70
puts ""
puts "WEBHOOK URL (configure in bug-report service):"
puts ""
puts "  #{webhook_url}"
puts ""
puts "Flow:"
puts "  Bug Report Service"
puts "       |"
puts "       v"
puts "  [Webhook Receiver] -> [Formatter] -+-> [Linear Creator]"
puts "                                     |"
puts "                                     +-> [Discord Notifier]"
puts ""
puts "Environment variable to set in bug-report Dokku app:"
puts ""
puts "  dokku config:set bug-report HUGINN_WEBHOOK_URL='#{webhook_url}'"
puts ""
puts "=" * 70
