import 'package:flutter/material.dart';
import 'package:rust_assistant/code_data_base.dart';
import 'package:rust_assistant/databeans/code.dart';
import 'package:rust_assistant/databeans/section_info.dart';
import 'package:rust_assistant/l10n/app_localizations.dart';

class CodeTablePage extends StatefulWidget {
  const CodeTablePage({super.key});

  @override
  State<CodeTablePage> createState() => _CodeTablePageState();
}

class _CodeTablePageState extends State<CodeTablePage> {
  List<SectionInfo> _sections = [];
  Map<String, List<Code>> _sectionCodes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 确保代码数据已加载
    await CodeDataBase.loadCode();
    
    // 获取所有节信息
    final sections = CodeDataBase.getSectionInfoList();
    
    // 获取所有代码
    final allCodes = CodeDataBase.getAllCodes();
    
    // 按节分组代码
    final Map<String, List<Code>> sectionCodes = {};
    for (var section in sections) {
      final sectionName = section.section;
      if (sectionName != null) {
        // 获取该节下的所有代码
        final List<Code> codesInSection = allCodes.where((code) => code.section == sectionName).toList();
        if (codesInSection.isNotEmpty) {
          sectionCodes[sectionName] = codesInSection;
        }
      }
    }
    
    setState(() {
      _sections = sections;
      _sectionCodes = sectionCodes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.codeTable),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _sections.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.noNode,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final SectionInfo section = _sections[index];
                    final String? sectionName = section.section;
                    List<Code> codes = <Code>[];
                    
                    if (sectionName != null && _sectionCodes.containsKey(sectionName)) {
                      final List<Code>? sectionCodes = _sectionCodes[sectionName];
                      if (sectionCodes != null) {
                        codes = sectionCodes;
                      }
                    }
                    
                    return _buildSectionCard(context, section, codes);
                  },
                ),
    );
  }

  Widget _buildSectionCard(BuildContext context, SectionInfo section, List<Code> codes) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(Icons.category),
        title: Text(
          section.section ?? AppLocalizations.of(context)!.unknownNode,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: section.translate != null ? Text(section.translate!) : null,
        children: codes.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)!.noCode,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              ]
            : codes.map<Widget>((code) => _buildCodeItem(context, code)).toList(),
      ),
    );
  }

  Widget _buildCodeItem(BuildContext context, Code code) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.code, color: Colors.blue),
          title: Text(
            code.code ?? AppLocalizations.of(context)!.unknownCode,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (code.interpreter != null)
                Text(AppLocalizations.of(context)!.enumType + '${code.interpreter}'),
              if (code.fileName != null)
                Text(AppLocalizations.of(context)!.codeFile + '${code.fileName}'),
              if (code.defaultKey != null)
                Text('${AppLocalizations.of(context)!.defaultKeyLabel}: ${code.defaultKey}'),
              if (code.defaultValue != null)
                Text('${AppLocalizations.of(context)!.defaultValueLabel}: ${code.defaultValue}'),
              if (code.minVersion != null || code.maxVersion != null)
                Text('${AppLocalizations.of(context)!.versionRangeLabel}: ${code.minVersion ?? ''}-${code.maxVersion ?? ''}'),
              if (code.allowRepetition != null)
                Text('${AppLocalizations.of(context)!.allowRepetitionLabel}: ${code.allowRepetition! ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no}'),
            ],
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _showCodeDetails(context, code);
          },
        ),
      ),
    );
  }

  void _showCodeDetails(BuildContext context, Code code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.codeDetailsTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(AppLocalizations.of(context)!.codeLabel, code.code),
              _buildDetailItem(AppLocalizations.of(context)!.sectionLabel, code.section),
              _buildDetailItem(AppLocalizations.of(context)!.interpreterLabel, code.interpreter),
              _buildDetailItem(AppLocalizations.of(context)!.fileNameLabel, code.fileName),
              _buildDetailItem(AppLocalizations.of(context)!.defaultKeyLabel, code.defaultKey),
              _buildDetailItem(AppLocalizations.of(context)!.defaultValueLabel, code.defaultValue),
              _buildDetailItem(AppLocalizations.of(context)!.minVersionLabel, code.minVersion?.toString()),
              _buildDetailItem(AppLocalizations.of(context)!.maxVersionLabel, code.maxVersion?.toString()),
              _buildDetailItem(AppLocalizations.of(context)!.allowRepetitionLabel, code.allowRepetition?.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value ?? AppLocalizations.of(context)!.notSet),
          ),
        ],
      ),
    );
  }
}