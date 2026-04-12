$ErrorActionPreference = "SilentlyContinue"

# Read hook input from stdin
$hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Extract the file path from the tool input
$filePath = $null
if ($hookInput.toolUse.input.filePath) {
    $filePath = $hookInput.toolUse.input.filePath
} elseif ($hookInput.toolUse.input.file_path) {
    $filePath = $hookInput.toolUse.input.file_path
}

if (-not $filePath) {
    # No file path found - not an edit operation we care about
    exit 0
}

# Check if this is a customization file we should validate
$isCustomizationFile = $false
if ($filePath -match '\.agent\.md$') { $isCustomizationFile = $true }
if ($filePath -match '\.instructions\.md$') { $isCustomizationFile = $true }
if ($filePath -match '\.prompt\.md$') { $isCustomizationFile = $true }
if ($filePath -match '[/\\]SKILL\.md$') { $isCustomizationFile = $true }

if (-not $isCustomizationFile) {
    exit 0
}

# Read the file
if (-not (Test-Path $filePath)) {
    exit 0
}
$content = Get-Content $filePath -Raw -Encoding UTF8

# Check for YAML frontmatter
$warnings = @()

if ($content -notmatch '^---\s*\r?\n') {
    $warnings += "Missing YAML frontmatter opening '---'"
}

# Extract frontmatter block
if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---') {
    $frontmatter = $Matches[1]

    # Check for tabs
    if ($frontmatter -match '\t') {
        $warnings += "Tabs found in frontmatter - use spaces only (YAML does not allow tabs for indentation)"
    }

    # Check for description field
    if ($frontmatter -notmatch '(?m)^description\s*:') {
        $warnings += "Missing 'description' field - this file will not be discoverable by agents"
    } else {
        # Check if description is empty
        if ($frontmatter -match '(?m)^description\s*:\s*$') {
            $warnings += "Empty 'description' field - add trigger keywords for discoverability"
        }
        # Check if description with colon is unquoted
        if ($frontmatter -match '(?m)^description\s*:\s*[^"''][^"'']*:\s') {
            $warnings += "Unquoted description containing a colon - wrap in quotes to prevent YAML parse failure"
        }
    }

    # For SKILL.md: check name field matches folder
    if ($filePath -match '[/\\]SKILL\.md$') {
        if ($frontmatter -match '(?m)^name\s*:\s*[''"]?([^''"\r\n]+)') {
            $skillName = $Matches[1].Trim()
            $folderName = Split-Path (Split-Path $filePath -Parent) -Leaf
            if ($skillName -ne $folderName) {
                $warnings += "Skill name '$skillName' does not match folder name '$folderName' - this causes silent discovery failure"
            }
        } else {
            $warnings += "Missing 'name' field in SKILL.md - required for skill discovery"
        }
    }

    # Check for applyTo: "**" on large files (instructions only)
    if ($filePath -match '\.instructions\.md$') {
        if ($frontmatter -match 'applyTo\s*:\s*[''"]?\*\*[''"]?') {
            $lineCount = ($content -split '\r?\n').Count
            if ($lineCount -gt 200) {
                $warnings += "applyTo: '**' on a $lineCount-line file - consider narrowing the glob or converting to on-demand loading"
            }
        }
    }

    # Check for agents with 8+ tools (Swiss-army pattern)
    if ($filePath -match '\.agent\.md$') {
        if ($frontmatter -match '(?m)^tools\s*:\s*\[([^\]]+)\]') {
            $toolList = $Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            if ($toolList.Count -ge 8) {
                $warnings += "Agent has $($toolList.Count) tools - consider splitting into focused agents with fewer tools"
            }
        }
    }
} else {
    if ($content -match '^---') {
        $warnings += "YAML frontmatter opened but never closed - missing closing '---'"
    }
}

# Output result
if ($warnings.Count -gt 0) {
    $fileName = Split-Path $filePath -Leaf
    $message = "Frontmatter validation warnings for ${fileName}:" + [Environment]::NewLine
    foreach ($w in $warnings) {
        $message += "  - $w" + [Environment]::NewLine
    }
    $result = @{
        continue = $true
        systemMessage = $message
    } | ConvertTo-Json -Compress
    Write-Output $result
}

exit 0
