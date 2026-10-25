import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../bidi.dart';
import '../document/ocr_document.dart';

/// Word (.docx) and Excel (.xlsx) files written directly as Office Open XML,
/// with right-to-left paragraphs, tables and sheets.
abstract final class OfficeExporters {
  static String _x(String s) =>
      const HtmlEscape(HtmlEscapeMode.element)
          .convert(s)
          .replaceAll('"', '&quot;')
          // characters XML 1.0 does not allow
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  static Uint8List _zip(Map<String, String> files) {
    final archive = Archive();
    files.forEach(
      (name, content) => archive.addFile(ArchiveFile.string(name, content)),
    );
    return ZipEncoder().encodeBytes(archive);
  }

  static const _xmlHead =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

  // ==================================================================== DOCX

  static const _w =
      'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';

  static Uint8List toDocx(OcrDocument doc, {String title = 'OCR'}) {
    final rtl = Bidi.mostlyRtl(doc.blocks.map((b) => b.plainText));
    final body = StringBuffer();
    for (var p = 0; p < doc.pages.length; p++) {
      if (p > 0) body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      for (final b in doc.pages[p].blocks) {
        body.write(_docxBlock(b));
      }
    }
    if (doc.isEmpty) body.write('<w:p/>');
    // A4, 2 cm margins
    body.write(
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" '
      'w:header="709" w:footer="709" w:gutter="0"/>${rtl ? '<w:bidi/>' : ''}</w:sectPr>',
    );

    return _zip({
      '[Content_Types].xml':
          '$_xmlHead<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
          '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
          '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
          '</Types>',
      '_rels/.rels':
          '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
          '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
          '</Relationships>',
      'docProps/core.xml':
          '$_xmlHead<cp:coreProperties '
          'xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
          'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
          '<dc:title>${_x(title)}</dc:title><dc:creator>Arabic OCR</dc:creator>'
          '</cp:coreProperties>',
      'word/_rels/document.xml.rels':
          '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>',
      'word/styles.xml': _docxStyles(rtl),
      'word/document.xml':
          '$_xmlHead<w:document $_w><w:body>$body</w:body></w:document>',
    });
  }

  static String _docxStyles(bool rtl) {
    String heading(int level, int halfPoints) =>
        '<w:style w:type="paragraph" w:styleId="Heading$level">'
        '<w:name w:val="heading $level"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>'
        '<w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="${level - 1}"/></w:pPr>'
        '<w:rPr><w:b/><w:bCs/><w:sz w:val="$halfPoints"/><w:szCs w:val="${halfPoints + 4}"/></w:rPr></w:style>';
    return '$_xmlHead<w:styles $_w>'
        '<w:docDefaults><w:rPrDefault><w:rPr>'
        '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Times New Roman"/>'
        '<w:sz w:val="24"/><w:szCs w:val="28"/>'
        '<w:lang w:val="en-US" w:bidi="ar-SA"/>'
        '</w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="300" w:lineRule="auto"/>${rtl ? '<w:bidi/>' : ''}</w:pPr></w:pPrDefault>'
        '</w:docDefaults>'
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>'
        '${heading(1, 36)}${heading(2, 30)}${heading(3, 26)}${heading(4, 24)}${heading(5, 24)}${heading(6, 24)}'
        '<w:style w:type="paragraph" w:styleId="Quote"><w:name w:val="Quote"/><w:basedOn w:val="Normal"/>'
        '<w:pPr><w:ind w:start="567" w:end="567"/></w:pPr><w:rPr><w:i/><w:iCs/><w:color w:val="555555"/></w:rPr></w:style>'
        '<w:style w:type="table" w:default="1" w:styleId="TableNormal"><w:name w:val="Normal Table"/>'
        '<w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblCellMar><w:top w:w="40" w:type="dxa"/>'
        '<w:start w:w="100" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/><w:end w:w="100" w:type="dxa"/>'
        '</w:tblCellMar></w:tblPr></w:style>'
        '</w:styles>';
  }

  static String _pPr({String? style, required bool rtl, String extra = ''}) =>
      '<w:pPr>${style != null ? '<w:pStyle w:val="$style"/>' : ''}$extra'
      '${rtl ? '<w:bidi/>' : '<w:bidi w:val="0"/>'}</w:pPr>';

  static final _rtlChar = RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');
  static final _ltrChar = RegExp(r'[A-Za-z\u00C0-\u024F]');

  static String _runs(List<TextRun> runs, bool paragraphRtl) {
    final b = StringBuffer();
    for (final r in runs) {
      // complex-script (Arabic) runs need w:rtl for their bold/size to apply
      final rtl =
          _rtlChar.hasMatch(r.text) ||
          (paragraphRtl && !_ltrChar.hasMatch(r.text));
      final props =
          '${r.bold ? '<w:b/><w:bCs/>' : ''}${r.italic ? '<w:i/><w:iCs/>' : ''}'
          '${rtl ? '<w:rtl/>' : ''}';
      final parts = r.text.split('\n');
      b.write('<w:r>${props.isEmpty ? '' : '<w:rPr>$props</w:rPr>'}');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) b.write('<w:br/>');
        if (parts[i].isNotEmpty) {
          b.write('<w:t xml:space="preserve">${_x(parts[i])}</w:t>');
        }
      }
      b.write('</w:r>');
    }
    return b.toString();
  }

  static String _para(List<TextRun> runs, {String? style, String extra = ''}) {
    final rtl = Bidi.isRtl(runs.plain);
    return '<w:p>${_pPr(style: style, rtl: rtl, extra: extra)}${_runs(runs, rtl)}</w:p>';
  }

  static String _docxBlock(DocBlock b) => switch (b) {
    HeadingBlock(:final level, :final runs) => _para(
      runs,
      style: 'Heading$level',
    ),
    ParagraphBlock(:final runs) => _para(runs),
    QuoteBlock(:final runs) => _para(runs, style: 'Quote'),
    RuleBlock() => '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="BBBBBB"/></w:pBdr></w:pPr></w:p>',
    ListBlock(:final items) => items.map((i) {
      final indent = 567 * (i.level + 1);
      return _para(
        [TextRun('${i.marker}\t'), ...i.runs],
        extra:
            '<w:tabs><w:tab w:val="start" w:pos="$indent"/></w:tabs>'
            '<w:spacing w:after="60"/><w:ind w:start="$indent" w:hanging="340"/>',
      );
    }).join(),
    TableBlock() => _docxTable(b),
  };

  static String _docxTable(TableBlock t) {
    if (t.columnCount == 0) return '';
    final rtl = Bidi.isRtl(t.plainText);
    const total = 9638; // text width in twips (A4 minus margins)
    final colW = total ~/ t.columnCount;
    final b = StringBuffer();
    if (t.caption != null) b.write(_para([TextRun(t.caption!, bold: true)]));
    const border = 'w:val="single" w:sz="4" w:space="0" w:color="9A948A"';
    b.write(
      '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>${rtl ? '<w:bidiVisual/>' : ''}'
      '<w:tblBorders><w:top $border/><w:start $border/><w:bottom $border/><w:end $border/>'
      '<w:left $border/><w:right $border/><w:insideH $border/><w:insideV $border/></w:tblBorders>'
      '<w:tblLayout w:type="autofit"/></w:tblPr><w:tblGrid>',
    );
    for (var c = 0; c < t.columnCount; c++) {
      b.write('<w:gridCol w:w="$colW"/>');
    }
    b.write('</w:tblGrid>');
    for (var r = 0; r < t.rowCount; r++) {
      final row = t.grid[r];
      final headerRow = row.every((s) => s?.cell.header ?? false);
      b.write('<w:tr>${headerRow ? '<w:trPr><w:tblHeader/></w:trPr>' : ''}');
      var c = 0;
      while (c < t.columnCount) {
        final slot = row[c];
        if (slot == null) {
          b.write(
            '<w:tc><w:tcPr><w:tcW w:w="$colW" w:type="dxa"/></w:tcPr><w:p/></w:tc>',
          );
          c++;
          continue;
        }
        final cell = slot.cell;
        final span = math.min(cell.colSpan, t.columnCount - slot.col);
        // only the first column of a span opens a cell; gridSpan covers the rest
        if (c != slot.col) {
          c++;
          continue;
        }
        final props = StringBuffer(
          '<w:tcW w:w="${colW * span}" w:type="dxa"/>',
        );
        if (span > 1) props.write('<w:gridSpan w:val="$span"/>');
        if (cell.rowSpan > 1) {
          props.write(
            slot.row == r ? '<w:vMerge w:val="restart"/>' : '<w:vMerge/>',
          );
        }
        if (cell.header) {
          props.write('<w:shd w:val="clear" w:color="auto" w:fill="F1EDE6"/>');
        }
        final content = slot.row == r
            ? cell.text
                  .split('\n')
                  .map((l) => _para([TextRun(l, bold: cell.header)]))
                  .join()
            : '<w:p/>';
        b.write(
          '<w:tc><w:tcPr>$props</w:tcPr>${content.isEmpty ? '<w:p/>' : content}</w:tc>',
        );
        c += span;
      }
      b.write('</w:tr>');
    }
    b.write('</w:tbl><w:p/>');
    return b.toString();
  }

  // ==================================================================== XLSX

  /// The document's tables, one sheet each.
  static Uint8List toXlsx(OcrDocument doc) {
    final tables = doc.tables;
    final files = <String, String>{};
    final sheets = StringBuffer();
    final rels = StringBuffer();
    final overrides = StringBuffer();
    for (var i = 0; i < math.max(1, tables.length); i++) {
      final n = i + 1;
      files['xl/worksheets/sheet$n.xml'] = i < tables.length
          ? _sheet(tables[i])
          : _emptySheet;
      sheets.write('<sheet name="Table $n" sheetId="$n" r:id="rId$n"/>');
      rels.write(
        '<Relationship Id="rId$n" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$n.xml"/>',
      );
      overrides.write(
        '<Override PartName="/xl/worksheets/sheet$n.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
      );
    }
    final stylesId = math.max(1, tables.length) + 1;
    files.addAll({
      '[Content_Types].xml':
          '$_xmlHead<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '$overrides</Types>',
      '_rels/.rels':
          '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>',
      'xl/workbook.xml':
          '$_xmlHead<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>$sheets</sheets></workbook>',
      'xl/_rels/workbook.xml.rels':
          '$_xmlHead<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '$rels<Relationship Id="rId$stylesId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>',
      'xl/styles.xml':
          '$_xmlHead<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
          '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
          '<fill><patternFill patternType="solid"><fgColor rgb="FFF1EDE6"/><bgColor indexed="64"/></patternFill></fill></fills>'
          '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>'
          '<border><left style="thin"><color rgb="FF9A948A"/></left><right style="thin"><color rgb="FF9A948A"/></right>'
          '<top style="thin"><color rgb="FF9A948A"/></top><bottom style="thin"><color rgb="FF9A948A"/></bottom><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
          '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
          '</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    });
    return _zip(files);
  }

  static const _emptySheet =
      '$_xmlHead<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData/></worksheet>';

  static String _col(int c) {
    var s = '';
    for (var n = c + 1; n > 0; n = (n - 1) ~/ 26) {
      s = String.fromCharCode(65 + (n - 1) % 26) + s;
    }
    return s;
  }

  static String _sheet(TableBlock t) {
    final rtl = Bidi.isRtl(t.plainText);
    final m = t.matrix;
    final widths = List<int>.filled(t.columnCount, 8);
    for (final row in m) {
      for (var c = 0; c < row.length; c++) {
        final longest = row[c]
            .split('\n')
            .fold<int>(0, (a, l) => math.max(a, l.length));
        widths[c] = math.max(widths[c], math.min(60, longest + 2));
      }
    }
    final b = StringBuffer(
      '$_xmlHead<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<sheetViews><sheetView workbookViewId="0"${rtl ? ' rightToLeft="1"' : ''}/></sheetViews><cols>',
    );
    for (var c = 0; c < widths.length; c++) {
      b.write(
        '<col min="${c + 1}" max="${c + 1}" width="${widths[c]}" customWidth="1"/>',
      );
    }
    b.write('</cols><sheetData>');
    for (var r = 0; r < t.rowCount; r++) {
      b.write('<row r="${r + 1}">');
      for (var c = 0; c < t.columnCount; c++) {
        final slot = t.grid[r][c];
        final style = (slot?.cell.header ?? false) ? 2 : 1;
        final ref = '${_col(c)}${r + 1}';
        final text = m[r][c];
        if (text.isEmpty) {
          b.write('<c r="$ref" s="$style"/>');
        } else {
          b.write(
            '<c r="$ref" s="$style" t="inlineStr"><is><t xml:space="preserve">${_x(text)}</t></is></c>',
          );
        }
      }
      b.write('</row>');
    }
    b.write('</sheetData>');
    final merges = <String>[];
    for (var r = 0; r < t.rowCount; r++) {
      for (var c = 0; c < t.columnCount; c++) {
        final s = t.grid[r][c];
        if (s == null || !s.isOriginAt(r, c)) continue;
        if (s.cell.colSpan == 1 && s.cell.rowSpan == 1) continue;
        final r2 = math.min(t.rowCount, r + s.cell.rowSpan) - 1;
        final c2 = math.min(t.columnCount, c + s.cell.colSpan) - 1;
        if (r2 > r || c2 > c) {
          merges.add(
            '<mergeCell ref="${_col(c)}${r + 1}:${_col(c2)}${r2 + 1}"/>',
          );
        }
      }
    }
    if (merges.isNotEmpty) {
      b.write(
        '<mergeCells count="${merges.length}">${merges.join()}</mergeCells>',
      );
    }
    b.write('</worksheet>');
    return b.toString();
  }
}
