# Enhance Notification Service with Email Delivery

|  |  |  |  |
| --- | --- | --- | --- |
| **Summary** | This RFC proposes extending the existing Notification Service to support email delivery in addition to in-app notifications, using SendGrid as the email provider with webhook support for delivery tracking. | | |
| **Created** | 2025-01-15 | **Owner** | TBD |
| **Current Version** | 0.1.0 | **Contributors** | TBD |
| **Target Version** | 1.0.0 | **Other Stakeholders** | TBD |
| **Requirements** |  | **Approvers** | TBD |

---

This RFC consolidates email functionality across the product ecosystem and eliminates the need for individual applications to manage their own email infrastructure.

## Background

### Current State

The existing mailing service is operational and provides basic email functionality required by our products. Several limitations have been identified:

- **Efficiency Issues**: Email processing is suboptimal and resource-intensive.
- **Scalability Limitations**: Service struggles with increased email volume.
- **Integration Challenges**: Difficult to integrate with cross-product notification needs.
- **Cost Inefficiencies**: Current implementation has higher operational costs than necessary.
- **Reliability Concerns**: Occasional delivery delays and failures during peak periods.

With the growth of our user base and the expansion of product offerings, email volume has increased significantly. The current mailing infrastructure is becoming strained and requires reconsideration to meet future demands.

### Desired State

The goal is to establish a mailing service that achieves:

- **Scalability**: Handle high email volume with minimal latency.
- **Reliability**: Consistent and dependable delivery.
- **Integration**: Seamless interoperability with existing and future technology stacks, including cross-product notifications.
- **Cost-Efficiency**: Balance operational cost against performance.
- **Flexibility**: Adapt to evolving business needs with minimal disruption.
- **User Experience**: Speed, efficiency, and accuracy across email interactions.

Related: RFC-042 Notification Service Architecture

## Proposal

Enhance the existing Notification Service (NS) to support email delivery in addition to in-app notifications by:

1. **Extending the database schema** to store email-specific data (templates, delivery status, SendGrid event data).
2. **Integrating with SendGrid** (already used for B2C emails) as the email provider.
3. **Implementing template management** for registering and serving email templates.
4. **Adding webhook support** to receive delivery events from SendGrid via an AWS Lambda security boundary.
5. **Supporting retry logic** for transient SendGrid failures based on HTTP status codes.
6. **Maintaining separation** between in-app and email notification types — a single RabbitMQ message cannot target both.

Applications continue to publish notification requests to RabbitMQ, now specifying `type: EMAIL` in addition to `type: IN_APP`.

## Abandoned Ideas

**Option 1: Separate Email Service**
Create a standalone email service independent of the Notification Service.
*Rejected because*: adds operational overhead (new service to deploy/monitor), duplicates patterns already established in NS, delays time-to-market.

**Option 2: Continue with Application-Level Email**
Keep email sending in individual applications.
*Rejected because*: does not solve scalability or consistency problems, increases maintenance burden, misses the opportunity for centralization.

## Implementation

### Architecture Overview

```
Application → RabbitMQ → Notification Service → SendGrid API
                                ↓
                         NS Database (templates, status)
                                ↑
SendGrid Webhook → AWS Lambda (security/validation) → NS Webhook Endpoint
```

### Database Schema

New tables:

- `EMAIL_TEMPLATES`: template metadata and content.
- `EMAIL_DELIVERY_STATUS`: per-email delivery status.
- `SENDGRID_EVENTS`: webhook event data from SendGrid.

Extend `NOTIFICATIONS` with email-specific fields (subject, recipient email, template ID).

### API

**Register Email Template**

```
POST /api/v1/email-templates
{
  "templateId": "loan-approval-notification",
  "subject": "Loan Application Approved",
  "htmlContent": "<html>...</html>",
  "textContent": "Plain text version..."
}
```

**Send Email Notification** (via RabbitMQ message)

```json
{
  "type": "EMAIL",
  "templateId": "loan-approval-notification",
  "recipient": "user@example.com",
  "data": {
    "customerName": "John Doe",
    "loanAmount": "$250,000"
  }
}
```

### Scope and Constraints

**In Scope**:
- Calling applications **can** pass template data (variables to populate a registered template).
- Webhook tracking for email delivery status.
- Support for both simple and complex email templates (HTML/CSS).
- Integration with the branding service for template-specific images.
- Usable across all applications in the ecosystem.

**Out of Scope / Constraints**:
- Calling applications **cannot** pass arbitrary templates — they must use a pre-registered template.
- A single RabbitMQ message **cannot** target both IN_APP and EMAIL — they must be requested separately.

### SendGrid Retry Logic

- **429 (Rate Limit)**: retry with exponential backoff.
- **5xx (Server Errors)**: retry with exponential backoff (max 3 attempts).
- **4xx (Client Errors)**: log error, do not retry.
- **2xx (Success)**: mark as sent, await webhook confirmation.

## Operationalization

### Logging

- **Email Delivery Attempts**: log each SendGrid API call with request ID, recipient, template, timestamp.
- **SendGrid Responses**: log all responses including success/failure/retry.
- **Webhook Events**: log all events received from SendGrid.
- **Storage**: Grafana for application logs; database for email delivery history.
- **Retention**: 90 days in Grafana; 1 year in database for compliance.

### Monitoring

- **Metrics**: email send rate, SendGrid API response times, delivery success rate, bounce rate, retry attempts.
- **Dashboards**: Grafana dashboard showing email volume, delivery rates, and errors.
- **Alerts**:
  - Delivery success rate drops below 95%.
  - SendGrid API latency exceeds 5 seconds.
  - Bounce rate exceeds 10%.

### Resilience

- **Health Check**: `/health` endpoint checks SendGrid connectivity.
- **Multiple Instances**: deploy 3 instances behind a load balancer.
- **Queue-Based**: RabbitMQ provides buffering during NS downtime.
- **Retry Logic**: exponential backoff for transient SendGrid failures (per Implementation).
- **Circuit Breaker**: stop sending to SendGrid if error rate exceeds threshold.

### Security

- **Network Security**: NS remains internal (not publicly accessible). AWS Lambda is the only public-facing component.
- **Lambda Security**: validates SendGrid webhook signature and payload structure before forwarding to NS.
- **Authentication**: NS API requires service-to-service JWT authentication.
- **Data Encryption**: email content encrypted at rest in the database; TLS for in-transit traffic to SendGrid.
- **PII Handling**: email addresses and content treated as PII; comply with data retention policies.
- **Attack Surface**: NS does not need public endpoints; security enforcement happens at the Lambda layer before requests reach internal services.

