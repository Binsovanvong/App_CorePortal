$filePath = 'd:\StudioProjects\Project\core_portal\lib\screens\super_admin\super_admin_view.dart'
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Find the exact corrupted block and replace it
# The corruption starts after line "      nameEn = widget.appData!['titleEn'] ?? '';"
# and ends before "        child: Column("
# We need to find the pattern and replace

$searchStart = "      nameEn = widget.appData!['titleEn'] ?? '';"
$searchEnd = "      body: SingleChildScrollView("

$startIdx = $content.IndexOf($searchStart)
$endIdx = $content.IndexOf($searchEnd)

if ($startIdx -ge 0 -and $endIdx -ge 0) {
    $beforeBlock = $content.Substring(0, $startIdx + $searchStart.Length)
    $afterBlock = $content.Substring($endIdx)

    $replacement = @"

      url = widget.appData!['route'] ?? '';
      ruleType = _normalizeRuleTypeToEnum(
        widget.appData!['ruleType'] ?? 'GENERAL_DEPARTMENT',
      );
      ruleValue = widget.appData!['ruleValue'] ?? 'GDDTM';
    }
    if (!ruleTypeOptions.any((o) => o['value'] == ruleType)) {
      ruleType = 'GENERAL_DEPARTMENT';
    }
    nameKhCtrl = TextEditingController(text: nameKh);
    nameEnCtrl = TextEditingController(text: nameEn);
    urlCtrl = TextEditingController(text: url);
    ruleTypeCtrl = TextEditingController(text: ruleType);
    ruleValueCtrl = TextEditingController(text: ruleValue);
    isActive = widget.isEdit ? (widget.appData?['isActive'] ?? true) : true;
    _fetchRuleValuesForType(ruleType);
  }

  @override
  void dispose() {
    nameKhCtrl.dispose();
    nameEnCtrl.dispose();
    urlCtrl.dispose();
    ruleTypeCtrl.dispose();
    ruleValueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff8A6514),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildAppBarTitle(),
      ),
"@

    $newContent = $beforeBlock + $replacement + $afterBlock
    [System.IO.File]::WriteAllText($filePath, $newContent, [System.Text.Encoding]::UTF8)
    Write-Output "SUCCESS: Replaced corrupted block."
} else {
    Write-Output "ERROR: Could not find markers. startIdx=$startIdx endIdx=$endIdx"
}
