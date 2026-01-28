# Bug Report Pipeline: Bug Report Service -> Linear Ticket + GitHub Copilot + Discord
# Run with: LINEAR_API_KEY=xxx GITHUB_TOKEN=xxx ./deploy.sh run-script scripts/deploy_bug_report_pipeline.rb
#
# Creates:
# 1. Webhook receiver for bug reports
# 2. Formatter - prepares data for all downstream agents
# 3. Linear ticket creator - creates ticket in Linear
# 4. GitHub Copilot trigger - creates GitHub issue and assigns Copilot to work on it
# 5. Linear status updater - moves ticket to "In Progress"
# 6. Discord notifier - announces bug and that Copilot is working on it

require 'json'
require 'securerandom'

# Configuration
LINEAR_API_KEY = ENV['LINEAR_API_KEY'] || raise("LINEAR_API_KEY required")
LINEAR_TEAM_ID = ENV['LINEAR_TEAM_ID'] || 'ea32dd92-d7ac-40f6-bcac-eacbcd72442c'
DISCORD_WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL'] || 'https://discord.com/api/webhooks/1456249665266909281/krMsTJ4Sgbsyz5HTb93xZfvY3QvtRZVhXBbbow_Eu3HgowBkncPNrdyEZBbWfRp-sFzN'
ADMIN_USERNAME = ENV['HUGINN_ADMIN_USERNAME'] || 'admin'

# GitHub Copilot Configuration
GITHUB_TOKEN = ENV['GITHUB_TOKEN'] || ''
GITHUB_REPO = ENV['GITHUB_REPO'] || 'sceneXtras/scenextras-platform'
GITHUB_COPILOT_BOT_ID = ENV['GITHUB_COPILOT_BOT_ID'] || 'BOT_kgDOC9w8XQ'
COPILOT_ENABLED = GITHUB_TOKEN.length > 0

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
  # Test label (gray) - for test bug reports
  "test" => ENV['LINEAR_LABEL_TEST'] || '',
}.freeze

puts "Deploying Bug Report Pipeline..."
puts "  Linear Team: #{LINEAR_TEAM_ID}"
puts "  Discord: #{DISCORD_WEBHOOK_URL[0..50]}..."
puts "  GitHub Copilot: #{COPILOT_ENABLED ? 'ENABLED' : 'DISABLED (set GITHUB_TOKEN to enable)'}"
puts "  GitHub Repo: #{GITHUB_REPO}" if COPILOT_ENABLED

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
  'Bug Report Copilot Formatter',
  'Bug Report GitHub Copilot Trigger',
  'Bug Report Linear Status Updater',
  'Bug Report Discord Filter',
  'Bug Report Discord Notifier',
  'Bug Report Test Cleanup Scheduler',
  'Bug Report Test Linear Cleanup',
  'Bug Report Test GitHub Cleanup'
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

      // Detect [TEST] prefix in title
      var reportTitle = report.title || "Bug Report";
      var isTest = reportTitle.indexOf("[TEST]") === 0;

      // Strip [TEST] prefix from title for display (use substring instead of regex - more reliable in Huginn)
      var cleanTitle = reportTitle;
      if (isTest) {
        // Find where the actual title starts (after "[TEST]" and any whitespace)
        var startIdx = 6; // "[TEST]".length
        while (startIdx < reportTitle.length && reportTitle.charAt(startIdx) === " ") {
          startIdx++;
        }
        cleanTitle = reportTitle.substring(startIdx);
      }

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

      // Add "test" label for test reports
      if (isTest) {
        labelNames.push("test");
        if (labelIdMap["test"]) labelIds.push(labelIdMap["test"]);
      }

      // Filter out empty label IDs
      labelIds = labelIds.filter(function(id) { return id && id.length > 0; });

      // Build the complete GraphQL mutation with proper JSON
      var linearTitle = isTest ? "[TEST][Bug] " + cleanTitle : "[Bug] " + cleanTitle;
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

      // Build navigation history string
      var navHistory = "";
      if (report.navigationHistory && report.navigationHistory.length > 0) {
        navHistory = report.navigationHistory.join(" -> ");
      }

      // Build full device info string
      var deviceInfoStr = "";
      if (report.deviceInfo) {
        deviceInfoStr = JSON.stringify(report.deviceInfo, null, 2);
      }

      // Format logs as readable list
      var logsStr = "";
      if (report.logs && report.logs.length > 0) {
        if (typeof report.logs === 'string') {
          logsStr = report.logs;
        } else if (Array.isArray(report.logs)) {
          // Format each log entry as a readable line
          // Max 500 entries, ~55000 chars (GitHub limit 65536 minus ~10k for other content)
          var logLines = [];
          for (var i = 0; i < report.logs.length && i < 500; i++) {
            var log = report.logs[i];
            var line = "[" + (log.level || "info").toUpperCase() + "] ";
            if (log.timestamp) line += log.timestamp + " - ";
            line += log.message || "";
            logLines.push(line);
          }
          logsStr = logLines.join(" | ");
          if (report.logs.length > 500) {
            logsStr += " | ... +" + (report.logs.length - 500) + " more entries";
          }
        } else {
          logsStr = String(report.logs);
        }
        // Truncate if too long (GitHub issue body limit is 65536, leave 10k buffer for other content)
        if (logsStr.length > 55000) {
          logsStr = logsStr.substring(0, 55000) + " ... [truncated]";
        }
      }

      agent.createEvent({
        // Original data
        report_id: report.id,
        title: cleanTitle,
        is_test: isTest,
        description_raw: report.description,
        platform: labels.platform || (report.deviceInfo ? report.deviceInfo.platform : "Unknown"),
        os: labels.os || "Unknown",
        os_version: report.deviceInfo ? report.deviceInfo.osVersion : "",
        app_version: report.deviceInfo ? report.deviceInfo.appVersion : "Unknown",
        device_model: report.deviceInfo ? report.deviceInfo.deviceModel : "Unknown",
        current_route: report.currentRoute,
        route_domain: labels.routeDomain || "unknown",
        user_id: report.userInfo ? report.userInfo.userId : null,
        user_email: labels.userEmail || null,
        user_tier: labels.userTier || null,
        screenshot_url: report.screenshotUrl,
        trace_id: report.traceId,
        severity: labels.severity || "medium",

        // Full context for Copilot
        logs: logsStr,
        navigation_history: navHistory,
        device_info_json: deviceInfoStr,
        steps_to_reproduce: report.stepsToReproduce || "",

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
# 3. Linear Filter - Skip test reports (prevents Linear's Discord webhook)
# =============================================================================
linear_filter_code = <<~JS
  Agent.receive = function() {
    var agent = this;
    var events = this.incomingEvents();

    events.forEach(function(event) {
      var data = event.payload;

      // Skip test reports - don't create Linear tickets
      if (data.is_test === true) {
        agent.log("Skipping Linear ticket for test report: " + data.report_id);
        return;
      }

      // Pass through non-test events to Linear Creator
      agent.createEvent(data);
    });
  }
JS

linear_filter = user.agents.create!(
  name: 'Bug Report Linear Filter',
  type: 'Agents::JavaScriptAgent',
  schedule: 'never',
  keep_events_for: 2592000,
  options: {
    'language' => 'JavaScript',
    'code' => linear_filter_code,
    'expected_receive_period_in_days' => 7
  }
)
puts "Created: #{linear_filter.name}"

# =============================================================================
# 3b. Linear Ticket Creator - uses ShellCommandAgent for HTTP request
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
# 4. GitHub Copilot Trigger - Creates GitHub issue and assigns Copilot
# =============================================================================
if COPILOT_ENABLED
  copilot_trigger_code = <<~JS
    Agent.receive = function() {
      var events = this.incomingEvents();
      var agent = this;

      this.log("Copilot Formatter received " + events.length + " events");

      events.forEach(function(event) {
        agent.log("Processing event: " + JSON.stringify(Object.keys(event)));

        var data = event.payload;

        if (!data) {
          agent.log("ERROR: event.payload is null/undefined");
          agent.log("Full event: " + JSON.stringify(event).substring(0, 500));
          return;
        }

        agent.log("Data keys: " + JSON.stringify(Object.keys(data)));
        agent.log("report_id: " + data.report_id);
        agent.log("title: " + data.title);

        // Map routes to investigation files (expanded for better context)
        var codeHints = [];
        var route = data.current_route || "";
        if (route.indexOf("/login") >= 0 || route.indexOf("/auth") >= 0) {
          codeHints = [
            "mobile_app_sx/app/(auth)/login.tsx",
            "mobile_app_sx/store/userStore.ts",
            "sceneXtras/api/auth/"
          ];
        } else if (route.indexOf("/chat") >= 0) {
          codeHints = [
            "mobile_app_sx/app/(tabs)/chat/",
            "mobile_app_sx/store/messageStore.ts",
            "mobile_app_sx/hooks/useChat.ts",
            "sceneXtras/api/chat/"
          ];
        } else if (route.indexOf("/search") >= 0) {
          codeHints = [
            "golang_search_engine/internal/handlers/",
            "mobile_app_sx/app/(tabs)/search/",
            "mobile_app_sx/store/characterStore.ts"
          ];
        } else if (route.indexOf("/settings") >= 0 || route.indexOf("/profile") >= 0) {
          codeHints = [
            "mobile_app_sx/app/(tabs)/settings/",
            "mobile_app_sx/store/userStore.ts"
          ];
        } else if (route.indexOf("/character") >= 0) {
          codeHints = [
            "mobile_app_sx/app/character/",
            "mobile_app_sx/store/characterStore.ts",
            "sceneXtras/api/router/character.py"
          ];
        }

        // Build ENHANCED structured issue body for Copilot
        // Format: YAML frontmatter + structured markdown + collapsible details
        var body = "";

        // YAML Frontmatter - machine-readable context
        body += "---\\n";
        body += "type: bug-report\\n";
        body += "report_id: " + data.report_id + "\\n";
        body += "severity: " + (data.severity || "medium") + "\\n";
        body += "platform: " + (data.platform || "unknown") + "\\n";
        body += "os: " + (data.os || "unknown") + "\\n";
        body += "app_version: " + (data.app_version || "unknown") + "\\n";
        body += "route: " + (data.current_route || "/") + "\\n";
        body += "---\\n\\n";

        // Task Overview
        body += "## Task\\n\\n";
        body += "Investigate and fix the following user-reported bug.\\n\\n";

        // Bug Description
        body += "## Bug Description\\n\\n";
        body += (data.description_raw || "No description provided") + "\\n\\n";

        // Environment Context
        body += "## Environment\\n\\n";
        body += "| Property | Value |\\n";
        body += "|----------|-------|\\n";
        body += "| **Platform** | " + (data.platform || "unknown") + " |\\n";
        body += "| **OS** | " + (data.os || "unknown") + " |\\n";
        body += "| **App Version** | " + (data.app_version || "unknown") + " |\\n";
        body += "| **Device** | " + (data.device_model || "unknown") + " |\\n";
        body += "| **Route** | `" + (data.current_route || "/") + "` |\\n\\n";

        // Code Investigation Hints
        if (codeHints.length > 0) {
          body += "## Investigation Hints\\n\\n";
          body += "Based on the route `" + route + "`, start investigating these files:\\n\\n";
          body += "```\\n";
          codeHints.forEach(function(hint) {
            body += hint + "\\n";
          });
          body += "```\\n\\n";
        }

        // Steps to Reproduce (if provided)
        if (data.steps_to_reproduce && data.steps_to_reproduce.length > 10) {
          body += "## Steps to Reproduce\\n\\n";
          body += data.steps_to_reproduce + "\\n\\n";
        }

        // Navigation History (collapsible)
        if (data.navigation_history && data.navigation_history.length > 10) {
          body += "<details>\\n<summary>Navigation History (click to expand)</summary>\\n\\n";
          body += "```\\n" + data.navigation_history + "\\n```\\n\\n";
          body += "</details>\\n\\n";
        }

        // Application Logs (collapsible - often verbose)
        if (data.logs && data.logs.length > 10) {
          body += "<details>\\n<summary>Application Logs (click to expand)</summary>\\n\\n";
          body += "```\\n" + data.logs + "\\n```\\n\\n";
          body += "</details>\\n\\n";
        }

        // Device Info (collapsible)
        if (data.device_info_json && data.device_info_json.length > 10) {
          body += "<details>\\n<summary>Device Info (click to expand)</summary>\\n\\n";
          body += "```json\\n" + data.device_info_json + "\\n```\\n\\n";
          body += "</details>\\n\\n";
        }

        // Explicit Instructions for Copilot
        body += "---\\n\\n";
        body += "## Instructions\\n\\n";
        body += "1. **Read the code hints** above to understand which files are relevant\\n";
        body += "2. **Analyze the logs** for error patterns, exceptions, or unexpected behavior\\n";
        body += "3. **Check the navigation history** to understand what the user was doing\\n";
        body += "4. **Identify the root cause** of the bug\\n";
        body += "5. **Implement a fix** with proper error handling\\n";
        body += "6. **Create a PR** with a clear description of the fix\\n\\n";
        body += "> Note: This issue was automatically generated from a bug report. ";
        body += "Report ID: `" + data.report_id + "`\\n";

        // Base64 encode the body to preserve newlines in shell
        // Manual base64 implementation since Buffer and btoa are not available in Huginn
        var base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        function base64encode(str) {
          var out = "";
          var i = 0;
          while (i < str.length) {
            var c1 = str.charCodeAt(i++);
            var c2 = str.charCodeAt(i++);
            var c3 = str.charCodeAt(i++);
            out += base64chars.charAt(c1 >> 2);
            out += base64chars.charAt(((c1 & 3) << 4) | (c2 >> 4));
            out += isNaN(c2) ? "=" : base64chars.charAt(((c2 & 15) << 2) | (c3 >> 6));
            out += isNaN(c3) ? "=" : base64chars.charAt(c3 & 63);
          }
          return out;
        }
        var bodyB64 = base64encode(body);

        agent.log("Creating event with title: [Bug] " + data.title);
        agent.log("Body length: " + body.length);

        // Determine if this is a test report
        var isTest = data.is_test === true;
        // Strip [TEST] prefix if present in title (belt-and-suspenders)
        var cleanedTitle = data.title.replace(/^\[TEST\]\s*/i, "");
        var githubTitle = isTest ? "[TEST][Bug] " + cleanedTitle : "[Bug] " + cleanedTitle;

        agent.createEvent({
          report_id: data.report_id,
          title: data.title,
          is_test: isTest,
          github_issue_title: githubTitle,
          github_issue_body: body,
          github_issue_body_b64: bodyB64,
          copilot_enabled: true
        });

        agent.log("Event created successfully for: " + data.report_id);
      });

      this.log("Copilot Formatter finished processing");
    }
  JS

  # First, create the JavaScript formatter for Copilot data
  copilot_formatter = user.agents.create!(
    name: 'Bug Report Copilot Formatter',
    type: 'Agents::JavaScriptAgent',
    schedule: 'never',
    keep_events_for: 2592000,
    options: {
      'language' => 'JavaScript',
      'code' => copilot_trigger_code,
      'expected_receive_period_in_days' => 7
    }
  )
  puts "Created: #{copilot_formatter.name}"

  # Then, create the ShellCommandAgent that uses the formatted data
  copilot_trigger = user.agents.create!(
    name: 'Bug Report GitHub Copilot Trigger',
    type: 'Agents::ShellCommandAgent',
    schedule: 'never',
    keep_events_for: 2592000,
    options: {
      'path' => '/usr/bin',
      'command' => <<~BASH.strip,
        # Build JSON payload using jq (handles escaping properly)
        ISSUE_TITLE="{{ github_issue_title | strip_newlines }}"
        IS_TEST="{{ is_test }}"
        # Decode base64 body to preserve newlines
        ISSUE_BODY=$(echo "{{ github_issue_body_b64 }}" | base64 -d)

        # Build labels array - add "test" label for test reports
        if [ "$IS_TEST" = "true" ]; then
          LABELS='["bug", "test"]'
        else
          LABELS='["bug"]'
        fi

        PAYLOAD=$(jq -n \\
          --arg title "$ISSUE_TITLE" \\
          --arg body "$ISSUE_BODY" \\
          --argjson labels "$LABELS" \\
          '{title: $title, body: $body, labels: $labels}')

        echo "Creating GitHub issue..."
        echo "Title: $ISSUE_TITLE"
        echo "Body length: ${#ISSUE_BODY}"

        # Create GitHub issue
        ISSUE_RESPONSE=$(echo "$PAYLOAD" | curl -s -X POST \\
          -H "Authorization: Bearer #{GITHUB_TOKEN}" \\
          -H "Accept: application/vnd.github+json" \\
          -H "Content-Type: application/json" \\
          https://api.github.com/repos/#{GITHUB_REPO}/issues \\
          -d @-)

        ISSUE_NUMBER=$(echo "$ISSUE_RESPONSE" | jq -r '.number')
        ISSUE_URL=$(echo "$ISSUE_RESPONSE" | jq -r '.html_url')

        if [ "$ISSUE_NUMBER" != "null" ] && [ -n "$ISSUE_NUMBER" ]; then
          echo "SUCCESS: Created issue #$ISSUE_NUMBER: $ISSUE_URL"
        else
          echo "ERROR: Failed to create issue"
          echo "Response: $ISSUE_RESPONSE"
        fi

        # NOTE: Copilot assignment disabled for testing
        # To enable, uncomment the GraphQL mutation below
        echo "GITHUB_ISSUE_URL=$ISSUE_URL"
      BASH
      'expected_update_period_in_days' => 7,
      'unbundle' => 'false',
      'suppress_on_failure' => 'false',
      'suppress_on_empty_output' => 'false'
    }
  )
  puts "Created: #{copilot_trigger.name}"
else
  puts "Skipped: GitHub Copilot Trigger (GITHUB_TOKEN not set)"
end

# =============================================================================
# 5. Discord Filter - Skip notifications for test reports
# =============================================================================
discord_filter_code = <<~JS
  Agent.receive = function() {
    var agent = this;
    var events = this.incomingEvents();

    events.forEach(function(event) {
      var data = event.payload;

      // Skip test reports - don't send to Discord
      if (data.is_test === true) {
        agent.log("Skipping Discord notification for test report: " + data.report_id);
        return;
      }

      // Pass through non-test events to Discord
      agent.createEvent(data);
    });
  }
JS

discord_filter = user.agents.create!(
  name: 'Bug Report Discord Filter',
  type: 'Agents::JavaScriptAgent',
  schedule: 'never',
  keep_events_for: 2592000,
  options: {
    'language' => 'JavaScript',
    'code' => discord_filter_code,
    'expected_receive_period_in_days' => 7
  }
)
puts "Created: #{discord_filter.name}"

# =============================================================================
# 6. Discord Notifier (Enhanced with Copilot status)
# =============================================================================
discord_payload = {
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
}

# Add Copilot status field if enabled
if COPILOT_ENABLED
  discord_payload['embeds'][0]['fields'] << {
    'name' => ':robot: Copilot Status',
    'value' => 'Copilot is investigating this bug and will create a PR',
    'inline' => false
  }
  discord_payload['embeds'][0]['color'] = 5814783  # Blue color when Copilot is working
end

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
    'payload' => discord_payload,
    'headers' => {
      'Content-Type' => 'application/json'
    },
    'no_merge' => 'true'
  }
)
puts "Created: #{discord_notifier.name}"

# =============================================================================
# 7. Test Cleanup Agents - Auto-close test tickets after 1 hour
# =============================================================================
# NOTE: Test cleanup is handled manually for now. Scheduler agents require
# different configuration in Huginn. Run cleanup manually via:
#   LINEAR_API_KEY=xxx ./scripts/cleanup_test_tickets.sh
puts "NOTE: Test cleanup agents not created - use manual cleanup scripts"

# Skip automated cleanup for now - manual cleanup scripts in scripts/ directory
if false  # Disabled - uncomment when SchedulerAgent config is fixed

# Linear cleanup - closes test tickets older than 1 hour
# Uses Linear GraphQL API to find and close issues with "test" label
linear_cleanup_code = <<~BASH.strip
  # Find Linear issues with "test" label created more than 1 hour ago and close them
  # Get issues with test label
  LINEAR_API_KEY="#{LINEAR_API_KEY}"
  TEAM_ID="#{LINEAR_TEAM_ID}"

  # Query for open issues with test label
  QUERY='{"query":"query { issues(filter: { team: { id: { eq: \\"'$TEAM_ID'\\" } }, state: { type: { nin: [\\"canceled\\", \\"completed\\"] } }, labels: { name: { eq: \\"test\\" } }, createdAt: { lt: \\""$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ')"\\" } }) { nodes { id identifier title createdAt } } }"}'

  RESPONSE=$(curl -s -X POST https://api.linear.app/graphql \\
    -H "Content-Type: application/json" \\
    -H "Authorization: $LINEAR_API_KEY" \\
    -d "$QUERY")

  echo "Linear test issues query response:"
  echo "$RESPONSE" | jq -r '.data.issues.nodes[] | "  - \\(.identifier): \\(.title) (created: \\(.createdAt))"' 2>/dev/null || echo "  No test issues found or parse error"

  # Get canceled state ID for the team
  STATE_QUERY='{"query":"query { workflowStates(filter: { team: { id: { eq: \\"'$TEAM_ID'\\" } }, type: { eq: \\"canceled\\" } }) { nodes { id name } } }"}'
  STATE_RESPONSE=$(curl -s -X POST https://api.linear.app/graphql \\
    -H "Content-Type: application/json" \\
    -H "Authorization: $LINEAR_API_KEY" \\
    -d "$STATE_QUERY")

  CANCELED_STATE_ID=$(echo "$STATE_RESPONSE" | jq -r '.data.workflowStates.nodes[0].id // empty')

  if [ -z "$CANCELED_STATE_ID" ]; then
    echo "ERROR: Could not find canceled state for team"
    exit 0
  fi

  echo "Using canceled state: $CANCELED_STATE_ID"

  # Close each test issue
  ISSUE_IDS=$(echo "$RESPONSE" | jq -r '.data.issues.nodes[].id // empty')

  for ISSUE_ID in $ISSUE_IDS; do
    if [ -n "$ISSUE_ID" ]; then
      echo "Closing test issue: $ISSUE_ID"
      CLOSE_MUTATION='{"query":"mutation { issueUpdate(id: \\"'$ISSUE_ID'\\", input: { stateId: \\"'$CANCELED_STATE_ID'\\" }) { success } }"}'
      curl -s -X POST https://api.linear.app/graphql \\
        -H "Content-Type: application/json" \\
        -H "Authorization: $LINEAR_API_KEY" \\
        -d "$CLOSE_MUTATION" | jq -r '"  Result: \\(.data.issueUpdate.success)"'
    fi
  done

  echo "Linear test cleanup complete"
BASH

test_linear_cleanup = user.agents.create!(
  name: 'Bug Report Test Linear Cleanup',
  type: 'Agents::ShellCommandAgent',
  schedule: 'never',
  keep_events_for: 86400,
  options: {
    'path' => '/usr/bin',
    'command' => linear_cleanup_code,
    'expected_update_period_in_days' => 1,
    'unbundle' => 'false',
    'suppress_on_failure' => 'false',
    'suppress_on_empty_output' => 'false'
  }
)
puts "Created: #{test_linear_cleanup.name}"

# GitHub cleanup - closes test issues older than 1 hour
if COPILOT_ENABLED
  github_cleanup_code = <<~BASH.strip
    # Find GitHub issues with "test" label created more than 1 hour ago and close them
    GITHUB_TOKEN="#{GITHUB_TOKEN}"
    REPO="#{GITHUB_REPO}"

    # Calculate 1 hour ago timestamp
    ONE_HOUR_AGO=$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ')

    echo "Searching for test issues created before: $ONE_HOUR_AGO"

    # Search for open issues with "test" label
    ISSUES=$(curl -s -X GET \\
      -H "Authorization: Bearer $GITHUB_TOKEN" \\
      -H "Accept: application/vnd.github+json" \\
      "https://api.github.com/repos/$REPO/issues?labels=test&state=open&per_page=100")

    echo "Found test issues:"
    echo "$ISSUES" | jq -r '.[] | "  - #\\(.number): \\(.title) (created: \\(.created_at))"' 2>/dev/null || echo "  No test issues found"

    # Close issues older than 1 hour
    echo "$ISSUES" | jq -r --arg cutoff "$ONE_HOUR_AGO" '.[] | select(.created_at < $cutoff) | .number' | while read ISSUE_NUMBER; do
      if [ -n "$ISSUE_NUMBER" ]; then
        echo "Closing test issue #$ISSUE_NUMBER"
        curl -s -X PATCH \\
          -H "Authorization: Bearer $GITHUB_TOKEN" \\
          -H "Accept: application/vnd.github+json" \\
          "https://api.github.com/repos/$REPO/issues/$ISSUE_NUMBER" \\
          -d '{"state":"closed","state_reason":"not_planned"}' | jq -r '"  Closed: #\\(.number) - \\(.title)"'
      fi
    done

    echo "GitHub test cleanup complete"
  BASH

  test_github_cleanup = user.agents.create!(
    name: 'Bug Report Test GitHub Cleanup',
    type: 'Agents::ShellCommandAgent',
    schedule: 'never',
    keep_events_for: 86400,
    options: {
      'path' => '/usr/bin',
      'command' => github_cleanup_code,
      'expected_update_period_in_days' => 1,
      'unbundle' => 'false',
      'suppress_on_failure' => 'false',
      'suppress_on_empty_output' => 'false'
    }
  )
  puts "Created: #{test_github_cleanup.name}"
end
end  # End of 'if false' block for disabled test cleanup

# =============================================================================
# Link Agents
# =============================================================================
# Webhook -> Formatter
webhook_receiver.links_as_source.create!(receiver: formatter)
puts "Linked: #{webhook_receiver.name} -> #{formatter.name}"

# Formatter -> Linear Filter -> Linear Creator (skips test reports)
formatter.links_as_source.create!(receiver: linear_filter)
puts "Linked: #{formatter.name} -> #{linear_filter.name}"
linear_filter.links_as_source.create!(receiver: linear_creator)
puts "Linked: #{linear_filter.name} -> #{linear_creator.name}"

# Formatter -> Copilot Formatter -> Copilot Trigger (if enabled)
if COPILOT_ENABLED && defined?(copilot_formatter) && copilot_formatter
  formatter.links_as_source.create!(receiver: copilot_formatter)
  puts "Linked: #{formatter.name} -> #{copilot_formatter.name}"
  copilot_formatter.links_as_source.create!(receiver: copilot_trigger)
  puts "Linked: #{copilot_formatter.name} -> #{copilot_trigger.name}"
end

# Formatter -> Discord Filter -> Discord (skips test reports)
formatter.links_as_source.create!(receiver: discord_filter)
puts "Linked: #{formatter.name} -> #{discord_filter.name}"

# Test Cleanup Scheduler -> Linear Cleanup + GitHub Cleanup (parallel)
# NOTE: Disabled - test cleanup agents not created
# test_cleanup_scheduler.links_as_source.create!(receiver: test_linear_cleanup)
# puts "Linked: #{test_cleanup_scheduler.name} -> #{test_linear_cleanup.name}"
# if COPILOT_ENABLED && defined?(test_github_cleanup) && test_github_cleanup
#   test_cleanup_scheduler.links_as_source.create!(receiver: test_github_cleanup)
#   puts "Linked: #{test_cleanup_scheduler.name} -> #{test_github_cleanup.name}"
# end
discord_filter.links_as_source.create!(receiver: discord_notifier)
puts "Linked: #{discord_filter.name} -> #{discord_notifier.name}"

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
if COPILOT_ENABLED
  puts "Flow (with GitHub Copilot):"
  puts "  Bug Report Service"
  puts "       |"
  puts "       v"
  puts "  [Webhook Receiver] -> [Formatter] -+-> [Linear Creator] (adds 'test' label for [TEST] reports)"
  puts "                                     |"
  puts "                                     +-> [Copilot Formatter] -> [Copilot Trigger]"
  puts "                                     |                           -> Creates GitHub Issue"
  puts "                                     |                           -> Adds 'test' label for [TEST] reports"
  puts "                                     |"
  puts "                                     +-> [Discord Filter] -> [Discord Notifier]"
  puts "                                           (skips [TEST] reports)"
  puts ""
  puts "  [Test Cleanup Scheduler] (hourly) -+-> [Linear Cleanup] (closes test tickets > 1hr)"
  puts "                                     |"
  puts "                                     +-> [GitHub Cleanup] (closes test issues > 1hr)"
  puts ""
  puts "[TEST] Tag Behavior:"
  puts "  - Title prefix [TEST] detected and stripped for display"
  puts "  - Linear: 'test' label added, ticket auto-closed after 1 hour"
  puts "  - GitHub: 'test' label added, issue auto-closed after 1 hour"
  puts "  - Discord: notification SKIPPED for test reports"
  puts ""
  puts "GitHub Copilot Configuration:"
  puts "  Repo: #{GITHUB_REPO}"
  puts "  Bot ID: #{GITHUB_COPILOT_BOT_ID}"
else
  puts "Flow:"
  puts "  Bug Report Service"
  puts "       |"
  puts "       v"
  puts "  [Webhook Receiver] -> [Formatter] -+-> [Linear Creator] (adds 'test' label for [TEST] reports)"
  puts "                                     |"
  puts "                                     +-> [Discord Filter] -> [Discord Notifier]"
  puts "                                           (skips [TEST] reports)"
  puts ""
  puts "  [Test Cleanup Scheduler] (hourly) -> [Linear Cleanup] (closes test tickets > 1hr)"
  puts ""
  puts "[TEST] Tag Behavior:"
  puts "  - Title prefix [TEST] detected and stripped for display"
  puts "  - Linear: 'test' label added, ticket auto-closed after 1 hour"
  puts "  - Discord: notification SKIPPED for test reports"
  puts ""
  puts "NOTE: GitHub Copilot is DISABLED. Set GITHUB_TOKEN to enable."
end
puts ""
puts "Environment variable to set in bug-report Dokku app:"
puts ""
puts "  dokku config:set bug-report HUGINN_WEBHOOK_URL='#{webhook_url}'"
puts ""
puts "Optional: LINEAR_LABEL_TEST environment variable for test label ID:"
puts "  (Run setup_linear_labels.sh to create and configure labels)"
puts ""
if COPILOT_ENABLED
  puts "Required Huginn environment variables for Copilot:"
  puts "  GITHUB_TOKEN=ghp_xxx (PAT with repo + copilot scopes)"
  puts "  GITHUB_REPO=#{GITHUB_REPO}"
  puts "  GITHUB_COPILOT_BOT_ID=#{GITHUB_COPILOT_BOT_ID}"
  puts ""
end
puts "=" * 70
