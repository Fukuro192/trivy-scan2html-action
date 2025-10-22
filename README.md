# Trivy Scan2HTML Action

> [GitHub Action](https://github.com/features/actions) for [Trivy](https://github.com/aquasecurity/trivy) with [scan2html plugin](https://github.com/aquasecurity/trivy-plugin-scan2html) support

**Note:** This is a fork of [aquasecurity/trivy-action](https://github.com/aquasecurity/trivy-action) with integrated scan2html plugin support. Full documentation is in progress.

![](docs/images/trivy-action.png)

## What's Different?

This fork adds built-in support for the **scan2html plugin**, which generates interactive HTML reports from Trivy scan results. The plugin is **enabled by default** to provide a more user-friendly way to view and analyze vulnerabilities.

## Table of Contents

* [Quick Start](#quick-start)
* [Using scan2html plugin](#using-scan2html-plugin)
* [Disabling scan2html](#disabling-scan2html)
* [Key Inputs](#key-inputs)
* [Full Documentation](#full-documentation)

## Quick Start

Scan a Docker image and generate an interactive HTML report:

```yaml
name: build
on:
  push:
    branches:
      - main
  pull_request:
jobs:
  build:
    name: Build
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build an image from Dockerfile
        run: docker build -t docker.io/my-organization/my-app:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner with scan2html
        uses: Fukuro192/trivy-scan2html-action@master
        with:
          image-ref: 'docker.io/my-organization/my-app:${{ github.sha }}'
          output: 'trivy-results.html'
          severity: 'CRITICAL,HIGH'

      - name: Upload HTML report
        uses: actions/upload-artifact@v4
        with:
          name: trivy-scan2html-report
          path: trivy-results.html
```

The scan2html plugin is automatically installed and used by default. Download the HTML report from the workflow artifacts for viewing.

## Using scan2html plugin

The scan2html plugin is **enabled by default**. When you run a scan, the action will:
1. Automatically install the scan2html plugin
2. Transform the command from `trivy <scan-type>` to `trivy scan2html <scan-type>`
3. Generate an interactive HTML report

### Example: Scan filesystem

```yaml
- name: Run Trivy to scan filesystem
  uses: Fukuro192/trivy-scan2html-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    output: 'report.html'
```

### Example: Scan with all options

```yaml
- name: Run Trivy vulnerability scanner
  uses: Fukuro192/trivy-scan2html-action@master
  with:
    image-ref: 'alpine:latest'
    output: 'trivy-results.html'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
    ignore-unfixed: true
```

## Disabling scan2html

If you want to use the traditional Trivy output without scan2html, set `use-scan2html: 'false'`:

```yaml
- name: Run Trivy without scan2html
  uses: yourusername/trivy-scan2html-action@master
  with:
    image-ref: 'alpine:latest'
    format: 'table'
    use-scan2html: 'false'
```

## Key Inputs

Most commonly used inputs:

| Name              | Type    | Default                            | Description                                                      |
|-------------------|---------|------------------------------------|------------------------------------------------------------------|
| `scan-type`       | String  | `image`                            | Scan type, e.g. `image` or `fs`                                  |
| `image-ref`       | String  |                                    | Image reference, e.g. `alpine:3.10.2`                            |
| `scan-ref`        | String  | `/github/workspace/`               | Scan reference, e.g. `/github/workspace/` or `.`                 |
| `format`          | String  | `table`                            | Output format (`table`, `json`, `template`, `sarif`, etc.)       |
| `output`          | String  |                                    | Save results to a file                                           |
| `severity`        | String  | `UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL` | Severities of vulnerabilities to scan for                        |
| `exit-code`       | String  | `0`                                | Exit code when vulnerabilities are found                         |
| `ignore-unfixed`  | Boolean | false                              | Ignore unpatched/unfixed vulnerabilities                         |
| `version`         | String  | `v0.65.0`                          | Trivy version to use                                             |
| `use-scan2html`   | Boolean | **true**                           | Use the scan2html plugin to generate interactive HTML reports    |

For a complete list of all inputs, see the [action.yaml](action.yaml) file.

## Full Documentation

For complete documentation on all Trivy features, options, and use cases, please refer to:
- [Original Trivy Action Documentation](https://github.com/aquasecurity/trivy-action)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/latest/)
- [scan2html Plugin](https://github.com/aquasecurity/trivy-plugin-scan2html)

## License

This project inherits the same license as the original [trivy-action](https://github.com/aquasecurity/trivy-action).
