# Extract original content from pre-corruption steps (4261-line version)
$transcriptPath = 'C:\Users\Admin\.gemini\antigravity-ide\brain\8659825d-d3c0-4e34-9204-279ce7693622\.system_generated\logs\transcript_full.jsonl'
$lines = Get-Content $transcriptPath

# Need to reconstruct the section from line 3695 to 3870+ from the original file
# Step 110 (3710-3780), Step 131 (3680-3740), Step 218 (3760-3870)
# Also need step 109 or similar to see the initState -> build method original code

$stepsToExtract = @(102, 103, 109, 110, 112, 118, 121, 130, 136, 148, 151, 157, 160, 166, 172, 178, 184, 190, 196, 207, 211)

foreach ($i in 0..($lines.Count-1)) {
    try {
        $obj = ConvertFrom-Json $lines[$i] -ErrorAction SilentlyContinue
        if ($obj.type -eq 'VIEW_FILE' -and $obj.content -match 'super_admin_view\.dart' -and $obj.content -match 'Total Lines: 4261') {
            $filename = "d:\StudioProjects\Project\core_portal\orig_step_$($obj.step_index).txt"
            [System.IO.File]::WriteAllText($filename, $obj.content, [System.Text.Encoding]::UTF8)
            Write-Output "Saved step $($obj.step_index) content to $filename (length: $($obj.content.Length))"
        }
    } catch {}
}
