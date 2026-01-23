# Discord Revenue Monitoring Scenario
# Run with: ./deploy.sh run-script scripts/deploy_discord_monitor.rb
#
# Creates a complete webhook -> formatter -> Discord pipeline for:
# - RevenueCat webhooks
# - Stripe webhooks
# - Custom payment events

require 'json'

# Configuration (override via ENV or modify directly)
DISCORD_WEBHOOK_URL = ENV['DISCORD_WEBHOOK_URL'] || 'YOUR_DISCORD_WEBHOOK_URL'
ADMIN_USERNAME = ENV['HUGINN_ADMIN_USERNAME'] || 'admin'

puts "Deploying Discord Revenue Monitor..."

# Find or create user
user = User.find_by(username: ADMIN_USERNAME)
unless user
  puts "ERROR: User '#{ADMIN_USERNAME}' not found"
  exit 1
end

# Clean up existing agents with same names (idempotent)
existing_names = [
  'RevenueCat Webhook Receiver',
  'Stripe Webhook Receiver',
  'Revenue Event Formatter',
  'Discord Revenue Poster'
]
user.agents.where(name: existing_names).destroy_all
puts "Cleaned up existing agents"

# =============================================================================
# 1. RevenueCat Webhook Receiver
# =============================================================================
revenuecat_webhook = user.agents.create!(
  name: 'RevenueCat Webhook Receiver',
  type: 'Agents::WebhookAgent',
  schedule: 'never',
  keep_events_for: 604800, # 7 days
  options: {
    'secret' => SecureRandom.hex(32),
    'expected_receive_period_in_days' => 7,
    'payload_path' => '.'
  }
)
puts "Created: #{revenuecat_webhook.name}"
puts "  Webhook URL: /users/#{user.id}/web_requests/#{revenuecat_webhook.id}/#{revenuecat_webhook.options['secret']}"

# =============================================================================
# 2. Stripe Webhook Receiver
# =============================================================================
stripe_webhook = user.agents.create!(
  name: 'Stripe Webhook Receiver',
  type: 'Agents::WebhookAgent',
  schedule: 'never',
  keep_events_for: 604800,
  options: {
    'secret' => SecureRandom.hex(32),
    'expected_receive_period_in_days' => 7,
    'payload_path' => '.'
  }
)
puts "Created: #{stripe_webhook.name}"
puts "  Webhook URL: /users/#{user.id}/web_requests/#{stripe_webhook.id}/#{stripe_webhook.options['secret']}"

# =============================================================================
# 3. Revenue Event Formatter (JavaScript Agent)
# =============================================================================
formatter_code = <<~JS
  Agent.receive = function() {
    var events = this.incomingEvents();

    events.forEach(function(event) {
      var payload = event.payload;
      var result = {
        emoji: '💰',
        event_type: 'UNKNOWN',
        amount: 0,
        currency: 'USD',
        customer: 'Unknown',
        product: 'Unknown',
        source: 'unknown',
        timestamp: new Date().toISOString()
      };

      // RevenueCat events
      if (payload.event && payload.event.type) {
        result.source = 'RevenueCat';
        var rc = payload.event;

        switch(rc.type) {
          case 'INITIAL_PURCHASE':
            result.emoji = '🎉';
            result.event_type = 'NEW PURCHASE';
            break;
          case 'RENEWAL':
            result.emoji = '🔄';
            result.event_type = 'RENEWAL';
            break;
          case 'CANCELLATION':
            result.emoji = '❌';
            result.event_type = 'CANCEL';
            break;
          case 'UNCANCELLATION':
            result.emoji = '🔙';
            result.event_type = 'REACTIVATE';
            break;
          case 'BILLING_ISSUE':
            result.emoji = '⚠️';
            result.event_type = 'BILLING ISSUE';
            break;
          case 'SUBSCRIBER_ALIAS':
            return; // Skip alias events
          default:
            result.event_type = rc.type;
        }

        result.amount = (rc.price || 0);
        result.currency = rc.currency || 'USD';
        result.customer = rc.app_user_id || 'Unknown';
        result.product = rc.product_id || 'Unknown';
      }

      // Stripe events
      else if (payload.type && payload.type.startsWith('customer.subscription')) {
        result.source = 'Stripe';
        var sub = payload.data && payload.data.object;

        switch(payload.type) {
          case 'customer.subscription.created':
            result.emoji = '🎉';
            result.event_type = 'NEW SUBSCRIPTION';
            break;
          case 'customer.subscription.updated':
            result.emoji = '🔄';
            result.event_type = 'SUBSCRIPTION UPDATED';
            break;
          case 'customer.subscription.deleted':
            result.emoji = '❌';
            result.event_type = 'SUBSCRIPTION CANCELED';
            break;
          default:
            result.event_type = payload.type;
        }

        if (sub) {
          result.amount = (sub.plan && sub.plan.amount) ? sub.plan.amount / 100 : 0;
          result.currency = (sub.plan && sub.plan.currency) ? sub.plan.currency.toUpperCase() : 'USD';
          result.customer = sub.customer || 'Unknown';
          result.product = (sub.plan && sub.plan.nickname) || (sub.plan && sub.plan.id) || 'Unknown';
        }
      }

      // Stripe payment events
      else if (payload.type && payload.type.startsWith('payment_intent')) {
        result.source = 'Stripe';
        var pi = payload.data && payload.data.object;

        switch(payload.type) {
          case 'payment_intent.succeeded':
            result.emoji = '✅';
            result.event_type = 'PAYMENT SUCCESS';
            break;
          case 'payment_intent.payment_failed':
            result.emoji = '💔';
            result.event_type = 'PAYMENT FAILED';
            break;
          default:
            result.event_type = payload.type;
        }

        if (pi) {
          result.amount = pi.amount ? pi.amount / 100 : 0;
          result.currency = pi.currency ? pi.currency.toUpperCase() : 'USD';
          result.customer = pi.customer || 'Unknown';
        }
      }

      this.createEvent({ payload: result });
    });
  }
JS

formatter = user.agents.create!(
  name: 'Revenue Event Formatter',
  type: 'Agents::JavaScriptAgent',
  schedule: 'never',
  keep_events_for: 604800,
  options: {
    'language' => 'JavaScript',
    'code' => formatter_code,
    'expected_receive_period_in_days' => 7
  }
)
puts "Created: #{formatter.name}"

# =============================================================================
# 4. Discord Poster
# =============================================================================
discord_poster = user.agents.create!(
  name: 'Discord Revenue Poster',
  type: 'Agents::PostAgent',
  schedule: 'never',
  keep_events_for: 604800,
  options: {
    'post_url' => DISCORD_WEBHOOK_URL,
    'expected_receive_period_in_days' => 7,
    'content_type' => 'json',
    'method' => 'post',
    'payload' => {
      'embeds' => [
        {
          'title' => '{{ emoji }} {{ event_type }}',
          'color' => 5814783,
          'fields' => [
            { 'name' => 'Amount', 'value' => '${{ amount }} {{ currency }}', 'inline' => true },
            { 'name' => 'Product', 'value' => '{{ product }}', 'inline' => true },
            { 'name' => 'Source', 'value' => '{{ source }}', 'inline' => true },
            { 'name' => 'Customer', 'value' => '`{{ customer }}`', 'inline' => false }
          ],
          'timestamp' => '{{ timestamp }}'
        }
      ]
    }.to_json,
    'headers' => {
      'Content-Type' => 'application/json'
    },
    'no_merge' => 'true'
  }
)
puts "Created: #{discord_poster.name}"

# =============================================================================
# Link Agents (Create Event Flow)
# =============================================================================
# RevenueCat -> Formatter
revenuecat_webhook.links_as_source.create!(receiver: formatter)
puts "Linked: #{revenuecat_webhook.name} -> #{formatter.name}"

# Stripe -> Formatter
stripe_webhook.links_as_source.create!(receiver: formatter)
puts "Linked: #{stripe_webhook.name} -> #{formatter.name}"

# Formatter -> Discord
formatter.links_as_source.create!(receiver: discord_poster)
puts "Linked: #{formatter.name} -> #{discord_poster.name}"

# =============================================================================
# Summary
# =============================================================================
puts ""
puts "=" * 60
puts "DEPLOYMENT COMPLETE"
puts "=" * 60
puts ""
puts "Webhook URLs (append to your Huginn domain):"
puts ""
puts "RevenueCat:"
puts "  https://YOUR_HUGINN_DOMAIN/users/#{user.id}/web_requests/#{revenuecat_webhook.id}/#{revenuecat_webhook.options['secret']}"
puts ""
puts "Stripe:"
puts "  https://YOUR_HUGINN_DOMAIN/users/#{user.id}/web_requests/#{stripe_webhook.id}/#{stripe_webhook.options['secret']}"
puts ""
puts "Event Flow:"
puts "  RevenueCat Webhook ─┐"
puts "                      ├─> Revenue Formatter ──> Discord Poster"
puts "  Stripe Webhook ─────┘"
puts ""
puts "IMPORTANT: Update DISCORD_WEBHOOK_URL before running!"
puts "=" * 60
