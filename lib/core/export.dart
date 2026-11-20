import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'controller.dart';

String csvCell(Object? value) {
  var text = '$value';
  if (RegExp(r'^[=+@-]').hasMatch(text)) text = "'$text";
  return '"${text.replaceAll('"', '""')}"';
}

Future<void> exportProgress(AppController app, String format) async {
  late Uint8List bytes;
  late String mime;
  final stamp = app.dayKey;
  if (format == 'json') {
    final snapshot = deepCopy(app.data)
      ..remove('formation_cache')
      ..remove('source_cache');
    bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'CPNS Journey',
          'format_version': 1,
          'exported_at': DateTime.now().toUtc().toIso8601String(),
          'data': snapshot,
        }),
      ),
    );
    mime = 'application/json';
  } else if (format == 'csv') {
    final rows = <List<Object?>>[
      ['tipe', 'nama', 'status / nilai', 'tanggal'],
      for (final r in docRules)
        [
          'berkas',
          r['name'],
          app.documentStatus(r),
          (app.docs[r['id']] as Json?)?['updated_at'] ?? '',
        ],
      for (final a in app.results)
        ['latihan', a.title, '${a.total}/${a.maximum}', a.json['submitted_at']],
      for (final c in (app.data['cycles'] as List).cast<Json>())
        for (final s in (c['stages'] as Json).entries)
          [
            'tahap ${c['year']}',
            s.key,
            s.value,
            (c['evidence'][s.key] as Json?)?['recorded_at'] ?? '',
          ],
    ];
    bytes = Uint8List.fromList(
      utf8.encode(
        '\uFEFF${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}',
      ),
    );
    mime = 'text/csv';
  } else {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text(
            'CPNS Journey',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Ringkasan persiapan - ${app.data['alias']}'),
          pw.Text(
            'Cycle ${app.cycle['year']} - pendidikan ${app.data['education']} - target ${app.data['target_city']}',
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Catatan pribadi. Bukan hasil seleksi resmi. Penempatan Medan belum dijamin.',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Checklist berkas',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Berkas', 'Status'],
            data: docRules
                .map((r) => [r['name'], app.documentStatus(r)])
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Riwayat latihan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (app.results.isEmpty)
            pw.Text('Belum ada latihan selesai.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Latihan', 'TWK', 'TIU', 'TKP', 'Total'],
              data: app.results
                  .map(
                    (a) => [
                      a.title,
                      '${a.scores['TWK']}',
                      '${a.scores['TIU']}',
                      '${a.scores['TKP']}',
                      '${a.total}/${a.maximum}',
                    ],
                  )
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Blueprint CAT 2024 bersifat historis, bukan ketentuan final 2026. Persyaratan final mengikuti SSCASN dan instansi.',
          ),
          pw.Text(
            'Sumber: https://sscasn.bkn.go.id/ | https://rekrutmen.kemenkeu.go.id/',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
        footer: (c) => pw.Text(
          'Ekspor $stamp WIB - ${c.pageNumber}/${c.pagesCount}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    );
    bytes = await doc.save();
    mime = 'application/pdf';
  }
  final filename = 'CPNS-Journey-$stamp.$format';
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mime, name: filename)],
      fileNameOverrides: [filename],
      subject: 'Ekspor progres CPNS Journey',
    ),
  );
}
