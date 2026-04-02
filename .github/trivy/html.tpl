<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Trivy Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      background: #f5f5f5;
      color: #333;
    }
    h1, h2, h3 {
      color: #222;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
      background: white;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 8px;
      text-align: left;
      vertical-align: top;
    }
    th {
      background: #1f4e79;
      color: white;
    }
    tr:nth-child(even) {
      background: #f9f9f9;
    }
    .severity-CRITICAL {
      color: #b30000;
      font-weight: bold;
    }
    .severity-HIGH {
      color: #d35400;
      font-weight: bold;
    }
    .severity-MEDIUM {
      color: #b58900;
      font-weight: bold;
    }
    .severity-LOW {
      color: #2c7a7b;
      font-weight: bold;
    }
    .severity-UNKNOWN {
      color: #666;
      font-weight: bold;
    }
    .section {
      margin-bottom: 30px;
      padding: 15px;
      background: white;
      border-radius: 6px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.08);
    }
  </style>
</head>
<body>
  <h1>Trivy Vulnerability Report</h1>
  {{- range . }}
    <div class="section">
      <h2>Target: {{ .Target }}</h2>
      <p><strong>Type:</strong> {{ .Type }}</p>

      {{- if .Vulnerabilities }}
      <table>
        <thead>
          <tr>
            <th>Package</th>
            <th>Vulnerability ID</th>
            <th>Severity</th>
            <th>Installed Version</th>
            <th>Fixed Version</th>
            <th>Title</th>
          </tr>
        </thead>
        <tbody>
          {{- range .Vulnerabilities }}
          <tr>
            <td>{{ .PkgName }}</td>
            <td>{{ .VulnerabilityID }}</td>
            <td class="severity-{{ .Severity }}">{{ .Severity }}</td>
            <td>{{ .InstalledVersion }}</td>
            <td>{{ .FixedVersion }}</td>
            <td>{{ .Title }}</td>
          </tr>
          {{- end }}
        </tbody>
      </table>
      {{- else }}
      <p>No vulnerabilities found in this target.</p>
      {{- end }}
    </div>
  {{- end }}
</body>
</html>