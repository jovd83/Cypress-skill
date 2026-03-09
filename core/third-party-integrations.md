# Third-Party Integrations

> **When to use**: Test app behavior around payment providers, analytics, maps, chat widgets, auth providers, and external APIs without introducing instability.

## Golden Rules

1. Do not automate third-party UI flows unless strictly required.
2. Prefer contract-level stubbing with `cy.intercept()`.
3. Validate your app's integration points (request payload, callback handling, error UI).
4. Keep one small real-integration smoke flow if business-critical.

## Integration Testing Modes

| Mode | Use For | Tradeoff |
|---|---|---|
| Full mock | Most UI behavior tests | Fast, deterministic, lower real-integration confidence |
| Partial pass-through | Validate request shape + selected real responses | Moderate speed, moderate confidence |
| Real integration smoke | Critical end-to-end sanity checks | Slow, flaky risk, highest confidence |

## Payments (Example: Stripe-like API)

```typescript
it('handles successful payment callback', () => {
  cy.intercept('POST', '**/api/payments/intent', {
    statusCode: 200,
    body: { clientSecret: 'pi_test_secret' }
  }).as('paymentIntent');

  cy.intercept('POST', '**/api/payments/confirm', {
    statusCode: 200,
    body: { status: 'succeeded', id: 'pay_123' }
  }).as('confirmPayment');

  cy.visit('/checkout');
  cy.findByLabelText('Card number').clear().type('4242424242424242');
  cy.findByLabelText('Expiration').clear().type('12/28');
  cy.findByLabelText('CVC').clear().type('123');
  cy.findByRole('button', { name: /pay now/i }).click();

  cy.wait('@paymentIntent');
  cy.wait('@confirmPayment');
  cy.findByText(/payment successful/i).should('be.visible');
});
```

## OAuth / SSO Providers

Cypress should avoid direct automation of provider-hosted login pages in most suites.

```typescript
it('handles SSO callback successfully', () => {
  cy.intercept('POST', '**/api/auth/callback', {
    statusCode: 200,
    body: { token: 'test-token', user: { id: 'u1', role: 'admin' } }
  }).as('ssoCallback');

  cy.visit('/login');
  cy.findByRole('button', { name: /continue with sso/i }).click();
  cy.wait('@ssoCallback');

  cy.location('pathname').should('include', '/dashboard');
});
```

## Analytics and Tracking

```typescript
it('sends analytics event without external flakiness', () => {
  cy.intercept('POST', '**/analytics/**', { statusCode: 204, body: '' }).as('analytics');

  cy.visit('/products');
  cy.findByRole('button', { name: /add to cart/i }).click();

  cy.wait('@analytics').then(({ request }) => {
    expect(request.body).to.have.property('eventName', 'add_to_cart');
  });
});
```

## Maps and Geocoding APIs

```typescript
it('renders location results from mocked geocoding API', () => {
  cy.intercept('GET', '**/geocode*', {
    statusCode: 200,
    body: {
      results: [{ formatted_address: 'Brussels, Belgium', lat: 50.8503, lng: 4.3517 }]
    }
  }).as('geocode');

  cy.visit('/store-locator');
  cy.findByLabelText('Location').clear().type('Brussels{enter}');

  cy.wait('@geocode');
  cy.findByText('Brussels, Belgium').should('be.visible');
});
```

## Feature Flag Providers

```typescript
it('enables feature-flagged checkout variant', () => {
  cy.intercept('GET', '**/api/flags*', {
    statusCode: 200,
    body: { newCheckout: true, upsellBanner: false }
  }).as('flags');

  cy.visit('/checkout');
  cy.wait('@flags');
  cy.findByTestId('new-checkout-layout').should('be.visible');
});
```

## Chat/Widget Embeds

```typescript
it('degrades gracefully when chat widget fails to load', () => {
  cy.intercept('GET', '**/chat-widget.js', { forceNetworkError: true }).as('chatWidget');

  cy.visit('/support');
  cy.wait('@chatWidget');
  cy.findByText(/chat unavailable/i).should('be.visible');
  cy.findByRole('link', { name: /email support/i }).should('be.visible');
});
```

## Contract Assertions for External Calls

```typescript
it('sends expected payload to external webhook proxy', () => {
  cy.intercept('POST', '**/api/integrations/slack/notify').as('slackNotify');

  cy.visit('/alerts');
  cy.findByRole('button', { name: /notify slack/i }).click();

  cy.wait('@slackNotify').then(({ request, response }) => {
    expect(request.body).to.include.keys(['channel', 'message']);
    expect(response && response.statusCode).to.eq(200);
  });
});
```

## Anti-Patterns

- Automating full third-party UI login/payment flows in every test.
- Hardcoding real API keys in tests.
- Using live third-party services for routine regression suite runs.
- Mocking impossible payload shapes that never occur in production.

## Related

- [core/network-mocking.md](network-mocking.md)
- [core/security-testing.md](security-testing.md)
- [core/authentication.md](authentication.md)
- [core/error-and-edge-cases.md](error-and-edge-cases.md)
