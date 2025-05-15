# `vanguard-cli`

While terribly pretending I'm some day-trader, Vanguard only displays accounts' accumulative total once a day, and they
lack a public, or perhaps easily, accessible HTTP API.

Individual accounts provide relatively live investments, yet do not show percentage changes until the next day's market open.

Maybe there's a solution to extract this data; an easier means to see live changes throughout the day.

> [!NOTE] **Disclaimer**
> I've been seeking a project that programmatically drives a browser session to perform some *marginally* useful task, written specifically in `go`; Go's
> vendoring + binaries make CLIs incredibly easy to install. Additionally, I want to abstract external system requirements (i.e. browser driver(s) and versioning).

## Overview

The purpose of the following project is to demonstrate the usage of a headless browser session.

### Related Tooling

Other projects of interest that make use of a browser via CLI:

| Tool                            | What the headless browser is used for                                                                    | Underlying engine        | Typical install                       |
|---------------------------------|----------------------------------------------------------------------------------------------------------|--------------------------|---------------------------------------|
| **aws-azure-login**             | Walks Azure AD SSO (incl. MFA) to obtain AWS credentials and write them to `~/.aws/credentials`.         | Puppeteer + Chromium     | `npm i -g aws-azure-login`            |
| **saml2aws** (browser provider) | Automates any SAML IdP (ADFS, Ping, Okta, …) to fetch a SAML assertion and exchange it for AWS STS keys. | Playwright / Chromium    | `brew install versent/taps/saml2aws`  |
| **okta-aws-cli**                | Drives Okta OIDC & Device flows (web or fully headless) to produce temporary AWS credentials.            | Headless Chrome          | `brew install okta/tap/okta-aws-cli`  |
| **lighthouse**                  | Runs performance, accessibility, and best-practice audits against a URL, emitting JSON/HTML reports.     | Chrome DevTools Protocol | `npm i -g lighthouse`                 |
| **pageres-cli**                 | Captures responsive screenshots (PNG) for one or many URLs at arbitrary resolutions.                     | Puppeteer / Chromium     | `npm i -g pageres-cli`                |
| **puppeteer-cli**               | Wrapper exposing Puppeteer’s screenshot + PDF features as one-liners.                                    | Puppeteer                | `npm i -g puppeteer-cli`              |
| **chrome-headless-render-pdf**  | Renders any URL or local HTML to print-quality PDF using Chrome’s `printToPDF` API.                      | Chrome DevTools Protocol | `npm i -g chrome-headless-render-pdf` |
