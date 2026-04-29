# Trustseal / Docuseal - Deep Product Dossier for Google Stitch Landing Page Generation

## 1) Product Identity

### Product name
- Primary product name in this codebase: `Trustseal` (based on README branding)
- Public/open-source references also include `Docuseal`

### Core one-liner
- Open-source platform for secure document preparation, form filling, eSignature workflows, and automated document processing.

### Positioning
- Alternative to legacy eSignature suites (DocuSign/PandaDoc style workflows)
- Built for both:
  - **Business users** (send/manage/sign docs at scale)
  - **Developers** (API, embedding, webhooks, automation)

### Primary value propositions
- Fast PDF form builder with WYSIWYG editing
- Multi-party signing in one workflow
- Strong compliance/security posture
- Highly extensible (API + embed + webhooks)
- Self-hosting capable + cloud-ready

---

## 2) Primary User Segments

### Business Operations Teams
- Need contract and approval workflows
- Need reminders, audit trails, completion tracking, archive handling
- Need role-based routing across multiple signers

### Legal / Compliance
- Need legally binding eSignatures
- Need identity verification options
- Need completion evidence and immutable audit records

### Product/Engineering Teams
- Need API-first eSignature workflows
- Need embeddable signing/form experiences in product UI
- Need event-driven integration via webhooks

### IT / Platform / DevOps
- Need deployment flexibility (Docker/self-hosting)
- Need external storage configuration options
- Need SSO/SAML, user management, admin controls

---

## 3) End-to-End Capability Overview

### A) Template Lifecycle
1. Upload or create template (PDF/DOCX/HTML routes available)
2. Define recipients (submitters)
3. Add and configure fields
4. Configure template preferences and delivery behavior
5. Share via link or create submissions

### B) Submission Lifecycle
1. Create submission from template (email/phone recipients)
2. Route invite order (`preserved` or `random`)
3. Submitters open, complete, decline, or remain pending
4. Documents are finalized and can be exported/downloaded
5. Events are emitted for webhook/API consumers

### C) Signer (Submitter) Lifecycle
Statuses represented in model logic:
- `awaiting` -> `sent` -> `opened` -> `completed`
- Alternate terminal path: `declined`

### D) Operational Lifecycle
- Active vs Archived templates/submissions
- Expiration handling for submissions
- Optional 2FA/link authorization checks before form access

---

## 4) Document/Template Sources Supported

### Template creation methods in platform/API
- PDF-based template creation
- DOCX-based template creation
- HTML-based template creation
- Template cloning and document replacement routes
- Merge tools and verification tools available via API scopes

### File format language from UI/landing
- Upload messaging includes support for: `PDF, DOCX, XLSX, JPEG, PNG, ZIP`
- Max upload size shown on landing: `100MB`

---

## 5) Field System - All Field Types and Semantics

The builder and API enumerate these field types:

1. `text` - free text input
2. `signature` - handwritten/typed/upload signature options
3. `initials` - initials capture
4. `date` - date input with configurable format
5. `number` - numeric input with formatting and min/max validation
6. `image` - image upload/input
7. `file` - file attachment upload
8. `select` - single dropdown choice
9. `checkbox` - boolean checkbox (single or grouped flow behavior)
10. `multiple` - multi-select options
11. `radio` - single choice radio options
12. `cells` - multi-cell/multiline structured text input
13. `stamp` - generated stamp element (optionally with logo)
14. `payment` - Stripe-backed payment field
15. `phone` - phone collection (+ verification workflows where enabled)
16. `verification` - identity verification step (`QeS`/`AeS` method options)
17. `kba` - knowledge-based authentication field
18. `heading` - non-input heading content element
19. `strikethrough` - visual strikeout markup
20. `redact` - visual redaction overlay/content masking element
21. `datenow` - date-signed/autoset style date behavior in builder choices

---

## 6) Field Configuration Matrix (What Can Be Configured)

### Universal-ish properties
- `required`
- `readonly`
- `default_value` (type-aware behavior)
- `title`, `description`
- `areas` (x/y/w/h/page/attachment_uuid based placement)
- `conditions` (field visibility/behavior conditions)
- `prefillable` (for supported field classes)

### Type-specific configuration

#### Text / Cells
- Validation presets (email/url/zip/numeric/letters, etc.)
- Custom regex validation
- Validation error message
- Length pattern validation (min/max style)
- Optional multiline toggle support in signer experience

#### Number
- Min/Max numeric validation
- Format options:
  - `none`
  - `usd`, `eur`, `gbp`
  - `comma`, `dot`, `space`
- Formula support (computed values)

#### Date
- Supported date formats include:
  - `MM/DD/YYYY`, `DD/MM/YYYY`, `YYYY-MM-DD`, `DD-MM-YYYY`, `DD.MM.YYYY`
  - Long formats like `MMM D, YYYY`, `MMMM D, YYYY`, etc.
- "Set signing date" behavior supported

#### Signature
- Format options:
  - `drawn`
  - `typed`
  - `drawn_or_typed`
  - `drawn_or_upload`
  - `upload`
  - plus default/any mode
- Optional signature ID
- Optional signing reason integration

#### Select / Radio / Multiple
- Option list modeling
- Default option support (for select/radio)

#### Checkbox
- Default checked behavior can force readonly style workflows

#### Stamp
- `with_logo` preference toggle

#### Verification
- Method options: `QeS` or `AeS`

#### Payment
- One-off amount mode
- Recurring price ID mode
- Payment link mode
- Currency selection and defaults
- Formula coupling for quantity/price scenarios
- Stripe connect status integration

---

## 7) Conditional Logic and Dynamic Behavior

### Conditional logic engine concepts
- Condition actions include patterns such as:
  - `empty`, `not_empty`
  - `checked`, `unchecked`
  - `equal`, `not_equal`
  - `contains`, `does_not_contain`
  - numeric comparisons (`greater_than`, `less_than`)
- Operations include OR composition support
- Conditions apply to:
  - field visibility/flow inclusion
  - schema/document visibility

### Dynamic documents and variables
- Template schema can include dynamic documents
- Variables schema and dynamic values are supported
- DOCX route explicitly supports variable tags (e.g. `[[variable_name]]`)

### Auto-detect fields
- Template builder can auto-detect fields from uploaded docs
- Detection pipeline uses visual + text heuristics and confidence scoring

---

## 8) Multi-Submitter Workflows

### Recipient model
- Templates define one or more submitters
- Defaults start with a single "First Party" pattern
- Submitters can be linked/ordered and role-named

### Sending order
- `preserved` order: signer N receives request after signer N-1 completes
- `random` order: all recipients can receive invites immediately

### Delivery channels
- Email delivery
- SMS-enabled flows (where configured)

### Access and verification
- Optional link access controls
- Optional phone/email 2FA checks
- Verification/KBA steps as part of signing flow

---

## 9) Submission and Completion Workflows

### In-form experience
- Step-based progression generated from field ordering + conditions
- Required-field gating before completion
- Supports minimized/expanded mobile-aware signing panel UX

### Completion artifacts and outputs
- Combined/merged document artifacts
- Audit trail artifact
- Download/send-copy controls after completion (configurable)

### System events and tracking
- Submitter view/click tracking endpoints
- Form and submission events APIs
- Webhook event families for templates/forms/submissions

---

## 10) Integration Surface

### API capabilities (high level)
- Templates CRUD and clone
- Submission creation and management
- Submitter lookup/update
- Documents retrieval
- Merge/verify tool endpoints
- Event listing endpoints

### Embedding
- Embedded signing form and builder references exist for:
  - React
  - Vue
  - Angular
  - JavaScript

### Webhooks
- Template, form, and submission webhook streams
- Event replay/resend mechanisms available in webhook settings area

---

## 11) Security, Trust, and Compliance Messaging

Use these as strong proof blocks on landing:
- SOC 2 certified
- ISO 27001 certified
- HIPAA compliance posture
- GDPR compliance posture (regional cloud references)
- Legally binding eSignature alignment (ESIGN/UETA/eIDAS messaging)

---

## 12) UI/UX Design Methodology

### Design philosophy
- Dark-first enterprise visual language with optional light mode
- Token-driven design system (`ds-*` and `stitch-*` variables)
- Consistent primitives across:
  - forms
  - navigation
  - cards
  - modals
  - toasts
  - data tables

### Methodology pillars
1. **Tokenized System**
   - Centralized color/surface/text/border/radius/spacing tokens
   - Enables theme switching with minimal component-specific overrides
2. **Component Consistency**
   - Reusable primitives for buttons, inputs, toggles, tabs, cards, alerts
3. **Accessible Interaction**
   - Focus rings, hover states, clear contrast hierarchy
4. **Progressive Disclosure**
   - Complex settings exposed contextually in dropdowns/modals
5. **Responsive Workflows**
   - Mobile-optimized signing, minimized panel states, adaptive spacing
6. **Operational UX**
   - Explicit states for archived/expired/declined/completed flows

### Typography approach
- Primary font family: `Inter` + system fallbacks
- Strong display hierarchy (`ds-display`, `ds-h1...h6`)
- Readability-first body scale (`ds-body*`, `ds-label`, `ds-caption`)

---

## 13) Theme System and Color Schemes (Both Themes)

## 13.1 Shared Brand Palettes (Core Tokens)

### Primary palette
- `--ds-primary-50` `#e9eef5`
- `--ds-primary-100` `#cbd7e6`
- `--ds-primary-200` `#a5bbd3`
- `--ds-primary-300` `#7f9fbf`
- `--ds-primary-400` `#5b86ac`
- `--ds-primary-500` `#3a6c95`
- `--ds-primary-600` `#25547a`
- `--ds-primary-700` `#153d5f`
- `--ds-primary-800` `#0c2a46`
- `--ds-primary-900` `#0a192c`

### Secondary/Accent palette
- `--ds-secondary-50` `#e7fcf7`
- `--ds-secondary-100` `#c2f6ea`
- `--ds-secondary-200` `#99f0de`
- `--ds-secondary-300` `#6fe9d1`
- `--ds-secondary-400` `#46e3c4`
- `--ds-secondary-500` `#04be99` (core CTA accent)
- `--ds-secondary-600` `#03987a`
- `--ds-secondary-700` `#02725c`
- `--ds-secondary-800` `#014d3f`
- `--ds-secondary-900` `#003226`

### Neutral palette
- `--ds-neutral-50` `#f5f8fb` ... `--ds-neutral-900` `#0b1421`

### Status colors
- Success: `#22c55e`
- Error: `#ef4444`
- Warning: `#f59e0b`
- Info: `#0ea5e9`

## 13.2 Dark Theme (`docuseal-dark` / legacy `docuseal`)

### Surface stack
- Base: `#051427`
- Elevated: `#0d1c2f`
- Container/high: `#122033`, `#1d2b3e`, `#28354a`

### Text
- Primary text: `#d5e3fe`
- Muted text: `#93a3bc`

### Border/outline
- Border: `rgba(213, 227, 254, 0.15)`
- Outline family anchored around blue-gray neutrals

### Accent behavior
- Primary action background: `#04be99`
- Action text on accent: `#00382b`
- Focus ring: translucent teal (`--ds-ring`)

### Signature style
- High-contrast, deep surfaces + neon-teal CTA highlights

## 13.3 Light Theme (`docuseal-light`)

### Surface stack
- Base: `#f5f8fb`
- Elevated: `#ffffff`
- Container/high: `#ecf1f7`, `#dde6f0`, `#ccd9e8`

### Text
- Primary text: `#12233c`
- Muted text: `#4b5d75`

### Border/outline
- Border: `rgba(18, 35, 60, 0.14)`
- Outline: `#8fa3bb` and lighter variants

### Accent behavior
- Same brand accent family, with brighter surfaces
- Primary CTA remains teal (`#04be99`) with dark-green text (`#00382b`)

### Signature style
- Clean enterprise white cards over cool blue-gray background layers

---

## 14) Visual Design Rules for Generated Landing Page (for Stitch)

### Tone and visual direction
- Enterprise trust + modern product-led growth
- Dark theme as default hero variant, optional light mode section demos
- Use accent teal for conversion actions, metrics, and active highlights

### Recommended section order
1. Hero (value + dual CTA)
2. Social proof (logos + key metric)
3. Feature pillars (business + developer)
4. Workflow visualization (Template -> Submission -> Completion)
5. Field capability matrix
6. Security/compliance trust block
7. Integrations/API/Embed block
8. Final conversion CTA

### CTA framework
- Primary CTA: "Create Free Account"
- Secondary CTA: "Self-host on GitHub" or "Talk to Sales"
- Developer CTA: "Read API Reference" + "View Embed Docs"

---

## 15) Templates We Provide (Message to Convey on Landing)

### Template Types
- PDF templates
- DOCX templates with dynamic variables
- HTML-generated templates
- Cloneable/reusable templates

### Use-case template categories to present
- Sales agreements and proposals
- HR onboarding and policy acknowledgements
- Compliance approvals and attestations
- Healthcare intake/consent packets
- Finance/payment authorization forms
- Multi-party legal signature workflows

---

## 16) Key Workflows to Visualize on Landing

### Workflow A: Internal Team Signing
1. Upload/prepare template
2. Add internal approvers
3. Set preserved order
4. Send invites
5. Track opened/completed statuses
6. Export combined signed package + audit trail

### Workflow B: Customer-facing Embedded Signing
1. Create template via API
2. Embed signing form in app
3. Prefill customer data
4. Collect signature + verification
5. Receive webhook events
6. Store final docs in external storage

### Workflow C: High-assurance Signature Request
1. Add verification or KBA step
2. Add required signature reason
3. Enforce phone/email verification
4. Apply expiration policy
5. Capture immutable completion evidence

---

## 17) Proof Points and Feature Highlights for Conversion

- Open-source and self-hostable
- Multi-submitter workflows
- Advanced fields + conditional logic + formulas
- Payment-capable signing flows
- API + webhooks + embedding SDK ecosystem
- Security/compliance certifications
- Global language support in signing experience
- Mobile-optimized end-user journey

---

## 18) Copy-ready Messaging Snippets for Stitch

### Hero headline options
- "Secure eSignature Workflows for Teams and Developers"
- "From Document to Signed Outcome - Faster, Safer, Open-Source"
- "Build, Send, Sign, Automate - All in One Document Platform"

### Hero subheadline
- "Design reusable templates, collect signatures and structured data, automate follow-ups, and integrate everything into your product with API, embedding, and webhooks."

### Feature card headlines
- "Template Builder That Scales"
- "Advanced Field Logic and Validation"
- "Multi-Party Signing Workflows"
- "Identity and Trust Controls"
- "Developer-First Integration Layer"
- "Audit-Ready Document Output"

### Final CTA line
- "Start free in minutes, or deploy your own trusted signing stack on your infrastructure."

---

## 19) Stitch Generation Brief (Prompt-Ready)

Use this exact brief when feeding into Google Stitch:

"Create a premium SaaS landing page for Trustseal/Docuseal, an open-source document signing and workflow platform. The page must target both business and developer audiences. Include sections for hero, social proof, capabilities, workflow diagrams, field type matrix, security/compliance, integrations/API, and final conversion CTA. Visual style should follow a dark-first enterprise system with teal accent (`#04be99`) and optional light theme support. Emphasize multi-party signing, advanced field types (signature, initials, payment, verification, KBA, conditional fields), API + embed + webhooks, and compliance trust (SOC2/ISO27001/HIPAA/GDPR). Use concise conversion-focused copy, clear CTA hierarchy, high contrast accessibility, and polished modern SaaS component styling."

---

## 20) Deliverable Intent

This dossier is intentionally structured as:
- Product documentation
- Feature inventory
- UX/system design guide
- Landing page generation blueprint

It can be attached directly to Stitch as a high-context source to generate a powerful, accurate marketing landing page.

