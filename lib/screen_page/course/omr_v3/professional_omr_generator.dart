import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'omr_model.dart';

class ProfessionalOMRGenerator extends StatefulWidget {
  final OMRExamConfig config;

  const ProfessionalOMRGenerator({Key? key, required this.config}) : super(key: key);

  @override
  State<ProfessionalOMRGenerator> createState() => _ProfessionalOMRGeneratorState();
}

class _ProfessionalOMRGeneratorState extends State<ProfessionalOMRGenerator> {
  final GlobalKey _omrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional OMR Generator'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Generate PDF',
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _saveAsImage,
            tooltip: 'Save as Image',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printOMR,
            tooltip: 'Print OMR',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: _omrKey,
              child: ProfessionalOMRSheet(config: widget.config),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildPDFContent();
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      _showError('Failed to generate PDF: $e');
    }
  }

  pw.Widget _buildPDFContent() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          _buildPDFHeader(),
          _buildPDFTopSection(),
          _buildPDFStudentInfoSection(),
          _buildPDFAnswerSection(),
        ],
      ),
    );
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Center(
              child: pw.Text(
                'LOGO',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            children: [
              pw.Text(
                widget.config.examName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 5),
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Text(
                  'কোড নং',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTopSection() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Column(
        children: [
          _buildPDFBubbleRow(),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Text(
              'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFBubbleRow() {
    return pw.Container(
      height: 40,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Row(
        children: List.generate(30, (index) {
          return pw.Container(
            width: 25,
            height: 40,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
            child: pw.Center(
              child: pw.Container(
                width: 18,
                height: 18,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.black),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  pw.Widget _buildPDFStudentInfoSection() {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          _buildPDFInfoHeader(),
          _buildPDFInfoGrid(),
          _buildPDFBottomInfo(),
        ],
      ),
    );
  }

  pw.Widget _buildPDFInfoHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('পরীক্ষা'),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Text('রোল নম্বর'),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Text('রেজিস্ট্রেশন নম্বর'),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Text('বিষয় কোড'),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Text('সেট কোড'),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Text('পরীক্ষার্থীর স্বাক্ষর'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFInfoGrid() {
    List<String> subjects = [
      'প্রথম মেয়াদ',
      'দ্বিতীয় মেয়াদ',
      'অর্ধ-বার্ষিক',
      'বার্ষিক',
      'প্রাক-নির্বাচনী',
      'নির্বাচনী',
      'প্রস্তুতি মূল্যায়ন',
      'মডেল টেস্ট',
    ];

    return pw.Column(
      children: subjects.map((subject) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 30,
                decoration: pw.BoxDecoration(
                  border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                ),
                child: pw.Center(
                  child: pw.Container(
                    width: 15,
                    height: 15,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                  ),
                ),
              ),
              pw.Container(
                width: 100,
                padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                child: pw.Text(subject, style: const pw.TextStyle(fontSize: 10)),
              ),
              ...List.generate(10, (index) {
                return pw.Container(
                  width: 25,
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          index.toString(),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Container(
                          width: 15,
                          height: 15,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: PdfColors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              pw.Expanded(
                child: pw.Container(
                  height: 30,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildPDFBottomInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Text('নাম : '),
                pw.Expanded(child: pw.Container()),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Text('শ্রেণী : '),
                pw.Expanded(child: pw.Container()),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Text('রোল : '),
                pw.Expanded(child: pw.Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFAnswerSection() {
    return pw.Container(
      margin: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          _buildPDFAnswerHeader(),
          _buildPDFAnswerGrid(),
          _buildPDFFooter(),
        ],
      ),
    );
  }

  pw.Widget _buildPDFAnswerHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
      ),
      child: pw.Text(
        'বহু নির্বাচনী উত্তরপত্র',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPDFAnswerGrid() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              children: [
                pw.Text('পরীক্ষকের স্বাক্ষর ও তারিখ'),
                pw.SizedBox(height: 50),
                pw.Text('নির্দেশকের স্বাক্ষর ও তারিখ'),
                pw.SizedBox(height: 50),
                pw.Text('তত্ত্বাবধায়কের স্বাক্ষর ও তারিখ'),
                pw.SizedBox(height: 50),
                pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Center(
                    child: pw.Text('কলেজের সীলমোহর'),
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: _buildPDFAnswerBubbles(),
          ),
          pw.Expanded(
            flex: 1,
            child: _buildPDFRightPanel(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFAnswerBubbles() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Text(
              'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Row(
            children: [
              _buildPDFQuestionColumn(1, 20),
              _buildPDFQuestionColumn(21, 40),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFQuestionColumn(int start, int end) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text('প্রশ্ন\nনম্বর'),
                pw.Text('উত্তর'),
              ],
            ),
          ),
          ...List.generate(end - start + 1, (index) {
            int questionNumber = start + index;
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(
                    width: 30,
                    child: pw.Text(
                      questionNumber.toString(),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: ['ক', 'খ', 'গ', 'ঘ'].map((option) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              option,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Container(
                              width: 20,
                              height: 20,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(color: PdfColors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildPDFRightPanel() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColors.black)),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
            child: pw.Text('প্রাপ্ত নম্বর'),
          ),
          ...List.generate(16, (index) {
            return pw.Container(
              height: 30,
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              child: pw.Center(
                child: pw.Text((index + 1).toString()),
              ),
            );
          }),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: [
                pw.Text('প্রাপ্ত নম্বর\n(সংখ্যায়)'),
                pw.SizedBox(height: 10),
                pw.Text('প্রাপ্ত নম্বর\n(কথায়)'),
                pw.SizedBox(height: 10),
                pw.Text('সংশোধিত\nপ্রাপ্ত নম্বর'),
                pw.SizedBox(height: 10),
                pw.Text('পূর্ণমান'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Text('কক্ষ নং: '),
          pw.Text('বিভাগ: '),
          pw.Text('বিষয়: '),
          pw.Text('পত্র: '),
          pw.Text('শাখা: '),
        ],
      ),
    );
  }

  Future<void> _saveAsImage() async {
    try {
      final RenderRepaintBoundary boundary = _omrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/omr_sheet_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      _showSuccess('OMR sheet saved as image: $filePath');
    } catch (e) {
      _showError('Failed to save image: $e');
    }
  }

  Future<void> _printOMR() async {
    try {
      await Printing.sharePdf(
        bytes: await _generatePdfBytes(),
        filename: 'omr-sheet-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      _showError('Failed to print: $e');
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => _buildPDFContent(),
      ),
    );
    return pdf.save();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class ProfessionalOMRSheet extends StatelessWidget {
  final OMRExamConfig config;

  const ProfessionalOMRSheet({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTopSection(),
          _buildStudentInfoSection(),
          _buildAnswerSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
                child: const Icon(Icons.school, size: 40),
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    config.examName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: const Text(
                      'কোড নং',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          _buildBubbleRow(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: const Text(
              'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleRow() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: List.generate(30, (index) {
          return Container(
            width: 25,
            height: 40,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black, width: 0.5),
              ),
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          _buildInfoHeader(),
          _buildInfoGrid(),
          _buildBottomInfo(),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(5),
              child: const Text('পরীক্ষা'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              child: const Text('রোল নম্বর'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              child: const Text('রেজিস্ট্রেশন নম্বর'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              child: const Text('বিষয় কোড'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              child: const Text('সেট কোড'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.black)),
              ),
              child: const Text('পরীক্ষার্থীর স্বাক্ষর'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    List<String> subjects = [
      'প্রথম মেয়াদ',
      'দ্বিতীয় মেয়াদ',
      'অর্ধ-বার্ষিক',
      'বার্ষিক',
      'প্রাক-নির্বাচনী',
      'নির্বাচনী',
      'প্রস্তুতি মূল্যায়ন',
      'মডেল টেস্ট',
    ];

    return Column(
      children: subjects.map((subject) {
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 30,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.black)),
                ),
                child: Center(
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ),
              ),
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(subject, style: const TextStyle(fontSize: 12)),
              ),
              ...List.generate(10, (index) {
                return Container(
                  width: 25,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.black, width: 0.5)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          index.toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Text('নাম : '),
                Expanded(child: Container()),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Text('শ্রেণী : '),
                Expanded(child: Container()),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Text('রোল : '),
                Expanded(child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          _buildAnswerHeader(),
          _buildAnswerGrid(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAnswerHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black)),
      ),
      child: const Text(
        'বহু নির্বাচনী উত্তরপত্র',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAnswerGrid() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Text('পরীক্ষকের স্বাক্ষর ও তারিখ'),
                const SizedBox(height: 50),
                const Text('নির্দেশকের স্বাক্ষর ও তারিখ'),
                const SizedBox(height: 50),
                const Text('তত্ত্বাবধায়কের স্বাক্ষর ও তারিখ'),
                const SizedBox(height: 50),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black),
                  ),
                  child: const Center(
                    child: Text('কলেজের সীলমোহর'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildAnswerBubbles(),
          ),
          Expanded(
            flex: 1,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBubbles() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: const Text(
              'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Row(
            children: [
              _buildQuestionColumn(1, 20),
              _buildQuestionColumn(21, 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionColumn(int start, int end) {
    return Expanded(
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('প্রশ্ন\nনম্বর'),
                Text('উত্তর'),
              ],
            ),
          ),

          // Question rows
          ...List.generate(end - start + 1, (index) {
            int questionNumber = start + index;

            return Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Question number
                  SizedBox(
                    width: 30,
                    child: Text(
                      questionNumber.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Answer bubbles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['ক', 'খ', 'গ', 'ঘ'].map((option) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          children: [
                            Text(
                              option,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: const Text('প্রাপ্ত নম্বর'),
          ),
          ...List.generate(16, (index) {
            return Container(
              height: 30,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 0.5)),
              ),
              child: Center(
                child: Text((index + 1).toString()),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text('প্রাপ্ত নম্বর\n(সংখ্যায়)'),
                const SizedBox(height: 10),
                const Text('প্রাপ্ত নম্বর\n(কথায়)'),
                const SizedBox(height: 10),
                const Text('সংশোধিত\nপ্রাপ্ত নম্বর'),
                const SizedBox(height: 10),
                const Text('পূর্ণমান'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('কক্ষ নং: ${config.roomNumber}'),
          Text('বিভাগ: ${config.department}'),
          Text('বিষয়: ${config.subjectName}'),
          const Text('পত্র: '),
          Text('শাখা: ${config.branch}'),
        ],
      ),
    );
  }
}



// // professional_omr_generator.dart
// // Full, single-file implementation of a responsive A4 Professional OMR Generator
// // - Scales on-screen to A4 aspect ratio and maps to printable A4 in PDF
// // - All element sizes scale with page size (scale factor passed to sub-widgets)
// // - Includes PDF export (using `pdf` + `printing`) and screenshot-to-image capability
// // - Minimal external dependencies listed below
//
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
//
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
//
// // ------------------
// // Simple model class (previously in omr_model.dart)
// // ------------------
// class OMRExamConfigg {
//   final String examName;
//   final String subjectName;
//   final String department;
//   final String roomNumber;
//   final String branch;
//   final int totalQuestions;
//   final int columns; // number of columns for question bubbles
//
//   OMRExamConfigg({
//     this.examName = 'Sample Exam',
//     this.subjectName = 'Subject',
//     this.department = '',
//     this.roomNumber = '',
//     this.branch = '',
//     this.totalQuestions = 40,
//     this.columns = 2,
//   });
// }
//
// // ------------------
// // Constants for A4
// // ------------------
// const double A4_PX_WIDTH = 595.0; // PDF points (approx) - portrait width
// const double A4_PX_HEIGHT = 842.0; // PDF points - portrait height
//
// // ------------------
// // Main generator page (wraps the sheet in a responsive box)
// // ------------------
// class ProfessionalOMRGenerator extends StatefulWidget {
//   final OMRExamConfigg config;
//
//   const ProfessionalOMRGenerator({Key? key, required this.config}) : super(key: key);
//
//   @override
//   State<ProfessionalOMRGenerator> createState() => _ProfessionalOMRGeneratorState();
// }
//
// class _ProfessionalOMRGeneratorState extends State<ProfessionalOMRGenerator> {
//   final GlobalKey _repaintKey = GlobalKey();
//
//   @override
//   Widget build(BuildContext context) {
//     // The parent provides infinite height in a SingleChildScrollView; constrain the viewport
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Professional OMR Generator'),
//         backgroundColor: const Color(0xFF2C3E50),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.picture_as_pdf),
//             onPressed: _onGeneratePdf,
//             tooltip: 'Generate PDF',
//           ),
//           IconButton(
//             icon: const Icon(Icons.image),
//             onPressed: _onSaveAsImage,
//             tooltip: 'Save as Image',
//           ),
//           IconButton(
//             icon: const Icon(Icons.print),
//             onPressed: _onPrint,
//             tooltip: 'Print OMR',
//           ),
//         ],
//       ),
//       body: LayoutBuilder(builder: (context, constraints) {
//         // Compute scale to fit A4 inside available constraints while keeping aspect ratio
//         final double maxW = constraints.maxWidth;
//         final double maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height;
//
//         // We want to show full A4 or scaled-down A4 with margin
//         // Use a margin factor so UI isn't flush against edges
//         final double margin = 24.0;
//         final double availW = maxW - margin * 2;
//         final double availH = maxH - margin * 2;
//
//         final double scaleW = availW / A4_PX_WIDTH;
//         final double scaleH = availH / A4_PX_HEIGHT;
//         final double scale = scaleW < scaleH ? scaleW : scaleH;
//
//         // Minimum scale to avoid extremely tiny rendering on very small screens
//         final double finalScale = scale.clamp(0.35, 1.6);
//
//         // onscreen size in logical pixels
//         final double viewW = A4_PX_WIDTH * finalScale;
//         final double viewH = A4_PX_HEIGHT * finalScale;
//
//         return SingleChildScrollView(
//           padding: EdgeInsets.all(margin),
//           child: Center(
//             child: RepaintBoundary(
//               key: _repaintKey,
//               child: Container(
//                 width: viewW,
//                 height: viewH,
//                 color: Colors.grey[300], // background to show edges while developing
//                 child: Container(
//                   margin: const EdgeInsets.all(8.0 * 0.5),
//                   // inner white paper area with border
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: Colors.black, width: 1.8 * finalScale),
//                   ),
//                   child: ProfessionalOMRSheet(
//                     config: widget.config,
//                     scale: finalScale,
//                     pageSize: Size(A4_PX_WIDTH, A4_PX_HEIGHT),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   Future<void> _onGeneratePdf() async {
//     try {
//       final pdf = pw.Document();
//
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4,
//           build: (pw.Context context) {
//             return _buildPdfContent(context);
//           },
//         ),
//       );
//
//       await Printing.layoutPdf(onLayout: (format) async => pdf.save());
//     } catch (e) {
//       _showSnack('PDF generation failed: $e', isError: true);
//     }
//   }
//
//   pw.Widget _buildPdfContent(pw.Context context) {
//     final cfg = widget.config;
//     final double pageW = context.page.pageFormat.availableWidth;
//     final double pageH = context.page.pageFormat.availableHeight;
//
//     // Compute pdf scale relative to nominal A4 points
//     final double pdfScaleW = pageW / A4_PX_WIDTH;
//     final double pdfScaleH = pageH / A4_PX_HEIGHT;
//     final double pdfScale = pdfScaleW < pdfScaleH ? pdfScaleW : pdfScaleH;
//
//     return pw.Container(
//       width: pageW,
//       height: pageH,
//       color: PdfColors.white,
//       child: pw.Center(
//         child: pw.Container(
//           width: A4_PX_WIDTH * pdfScale,
//           height: A4_PX_HEIGHT * pdfScale,
//           decoration: pw.BoxDecoration(
//             border: pw.Border.all(color: PdfColors.black, width: 1.5 * pdfScale),
//             color: PdfColors.white,
//           ),
//           child: _PdfOMRSheet(
//             config: cfg,
//             scale: pdfScale,
//             pageSize: Size(pageW, pageH),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _onSaveAsImage() async {
//     try {
//       final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
//       if (boundary == null) {
//         _showSnack('No render object found', isError: true);
//         return;
//       }
//
//       final ui.Image img = await boundary.toImage(pixelRatio: 2.5);
//       final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//       if (byteData == null) throw 'Unable to capture image bytes';
//
//       final Uint8List pngBytes = byteData.buffer.asUint8List();
//       final dir = await getTemporaryDirectory();
//       final file = File('${dir.path}/omr_${DateTime.now().millisecondsSinceEpoch}.png');
//       await file.writeAsBytes(pngBytes);
//
//       _showSnack('Saved image to: ${file.path}');
//     } catch (e) {
//       _showSnack('Save image failed: $e', isError: true);
//     }
//   }
//
//   Future<void> _onPrint() async {
//     try {
//       final pdfBytes = await _generatePdfBytes();
//       await Printing.sharePdf(bytes: pdfBytes, filename: 'omr_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     } catch (e) {
//       _showSnack('Print failed: $e', isError: true);
//     }
//   }
//
//   Future<Uint8List> _generatePdfBytes() async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) => _buildPdfContent(context),
//       ),
//     );
//     return pdf.save();
//   }
//
//   void _showSnack(String message, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//       ),
//     );
//   }
// }
//
// // ------------------
// // On-screen OMR sheet widget. It receives a `scale` parameter and uses it to compute
// // sizes so the whole sheet scales properly. All constants are expressed relative to the
// // nominal A4 point system (same as PDF points) then multiplied by the provided scale.
// // ------------------
// class ProfessionalOMRSheet extends StatelessWidget {
//   final OMRExamConfigg config;
//   final double scale; // how many logical pixels per A4 point on screen
//   final Size pageSize; // nominal A4 size in points
//
//   const ProfessionalOMRSheet({Key? key, required this.config, required this.scale, required this.pageSize}) : super(key: key);
//
//   double s(double points) => points * scale; // helper to convert PDF points -> logical pixels
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(s(8)),
//       child: Material(
//         color: Colors.white,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildHeader(),
//             SizedBox(height: s(8)),
//             _buildTopSection(),
//             SizedBox(height: s(8)),
//             _buildStudentInfoSection(),
//             SizedBox(height: s(8)),
//             Expanded(child: _buildAnswerSection()),
//             SizedBox(height: s(8)),
//             _buildFooter(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return SizedBox(
//       height: s(72),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: s(60),
//             height: s(60),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.black, width: s(1.2)),
//             ),
//             child: Icon(Icons.school, size: s(36)),
//           ),
//           SizedBox(width: s(16)),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(config.examName, style: TextStyle(fontSize: s(18), fontWeight: FontWeight.bold)),
//               SizedBox(height: s(6)),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: s(14), vertical: s(6)),
//                 decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(1.0))),
//                 child: Text('কোড নং', style: TextStyle(fontSize: s(12))),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTopSection() {
//     return Column(
//       children: [
//         _buildBubbleRow(),
//         SizedBox(height: s(8)),
//         Container(
//           padding: EdgeInsets.all(s(8)),
//           decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(1.0))),
//           child: Text(
//             'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
//             style: TextStyle(fontSize: s(12), fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBubbleRow() {
//     // Show 30 small bubbles for codes (example)
//     const int bubbleCount = 30;
//     return Container(
//       height: s(40),
//       decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(1.0))),
//       child: Row(
//         children: List.generate(bubbleCount, (index) {
//           return Container(
//             width: s(25),
//             height: s(40),
//             decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.black, width: s(0.5)))),
//             child: Center(
//               child: Container(
//                 width: s(18),
//                 height: s(18),
//                 decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: s(1.0))),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
//
//   Widget _buildStudentInfoSection() {
//     return Container(
//       padding: EdgeInsets.all(s(6)),
//       decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(1.0))),
//       child: Column(
//         children: [
//           _buildInfoHeader(),
//           SizedBox(height: s(6)),
//           _buildInfoGrid(),
//           SizedBox(height: s(6)),
//           _buildBottomInfo(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoHeader() {
//     return Container(
//       padding: EdgeInsets.all(s(4)),
//       decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.8)))),
//       child: Row(
//         children: [
//           Expanded(flex: 1, child: Padding(padding: EdgeInsets.all(s(3)), child: Text('পরীক্ষা', style: TextStyle(fontSize: s(10))))),
//           Expanded(flex: 2, child: Container(padding: EdgeInsets.all(s(3)), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('রোল নম্বর', style: TextStyle(fontSize: s(10))))),
//           Expanded(flex: 2, child: Container(padding: EdgeInsets.all(s(3)), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('রেজিস্ট্রেশন নম্বর', style: TextStyle(fontSize: s(10))))),
//           Expanded(flex: 1, child: Container(padding: EdgeInsets.all(s(3)), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('বিষয় কোড', style: TextStyle(fontSize: s(10))))),
//           Expanded(flex: 1, child: Container(padding: EdgeInsets.all(s(3)), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('সেট কোড', style: TextStyle(fontSize: s(10))))),
//           Expanded(flex: 2, child: Container(padding: EdgeInsets.all(s(3)), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('পরীক্ষার্থীর স্বাক্ষর', style: TextStyle(fontSize: s(10))))),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoGrid() {
//     final List<String> subjects = [
//       'প্রথম মেয়াদ',
//       'দ্বিতীয় মেয়াদ',
//       'অর্ধ-বার্ষিক',
//       'বার্ষিক',
//       'প্রাক-নির্বাচনী',
//       'নির্বাচনী',
//       'প্রস্তুতি মূল্যায়ন',
//       'মডেল টেস্ট',
//     ];
//
//     return Column(
//       children: subjects.map((subject) {
//         return Container(
//           height: s(32),
//           decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.5)))),
//           child: Row(
//             children: [
//               Container(width: s(20), height: s(30), decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.black, width: s(0.8)))), child: Center(child: Container(width: s(14), height: s(14), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: s(0.9)))))),
//               Container(width: s(100), padding: EdgeInsets.symmetric(horizontal: s(6)), child: Text(subject, style: TextStyle(fontSize: s(10)))),
//               ...List.generate(10, (index) {
//                 return Container(
//                   width: s(25),
//                   height: s(30),
//                   decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.black, width: s(0.5)))),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(index.toString(), style: TextStyle(fontSize: s(8))),
//                         SizedBox(height: s(2)),
//                         Container(width: s(14), height: s(14), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: s(0.8)))),
//                       ],
//                     ),
//                   ),
//                 );
//               }),
//               Expanded(child: Container(height: s(30), decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))))),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildBottomInfo() {
//     return Container(
//       padding: EdgeInsets.all(s(6)),
//       child: Row(
//         children: [
//           Expanded(child: Row(children: [Text('নাম : ', style: TextStyle(fontSize: s(10))), Expanded(child: Container())])),
//           Expanded(child: Row(children: [Text('শ্রেণী : ', style: TextStyle(fontSize: s(10))), Expanded(child: Container())])),
//           Expanded(child: Row(children: [Text('রোল : ', style: TextStyle(fontSize: s(10))), Expanded(child: Container())])),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnswerSection() {
//     // Layout: left panel signatures, middle bubbles, right result panel
//     return Container(
//       padding: EdgeInsets.all(s(6)),
//       decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(1.0))),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(flex: 2, child: _buildSignaturesColumn()),
//           SizedBox(width: s(8)),
//           Expanded(flex: 6, child: _buildAnswerBubbles()),
//           SizedBox(width: s(8)),
//           Expanded(flex: 2, child: _buildRightPanel()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSignaturesColumn() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('পরীক্ষকের স্বাক্ষর ও তারিখ', style: TextStyle(fontSize: s(10))),
//         SizedBox(height: s(24)),
//         Text('নির্দেশকের স্বাক্ষর ও তারিখ', style: TextStyle(fontSize: s(10))),
//         SizedBox(height: s(24)),
//         Text('তত্ত্বাবধায়কের স্বাক্ষর ও তারিখ', style: TextStyle(fontSize: s(10))),
//         SizedBox(height: s(24)),
//         Container(width: s(100), height: s(100), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: s(1.0))), child: Center(child: Text('কলেজের সীলমোহর', style: TextStyle(fontSize: s(8))),)),
//       ],
//     );
//   }
//
//   Widget _buildAnswerBubbles() {
//     // Arrange questions into `config.columns` columns.
//     final int total = config.totalQuestions;
//     final int cols = config.columns > 0 ? config.columns : 2;
//     final int perColumn = (total / cols).ceil();
//
//     return Container(
//       decoration: BoxDecoration(border: Border.all(color: Colors.black, width: s(0.8))),
//       child: Column(
//         children: [
//           Container(padding: EdgeInsets.all(s(6)), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে', style: TextStyle(fontSize: s(11)))),
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: List.generate(cols, (cIndex) {
//                 final int start = cIndex * perColumn + 1;
//                 final int end = ((cIndex + 1) * perColumn).clamp(0, total);
//                 return Expanded(child: _buildQuestionColumn(start, end));
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuestionColumn(int start, int end) {
//     final List<String> options = ['ক', 'খ', 'গ', 'ঘ'];
//
//     return Column(
//       children: [
//         Container(padding: EdgeInsets.all(s(6)), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.8)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text('প্রশ্ন\nনম্বর', style: TextStyle(fontSize: s(10))), Text('উত্তর', style: TextStyle(fontSize: s(10)))])),
//         Expanded(
//           child: ListView.builder(
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: (end - start + 1) > 0 ? (end - start + 1) : 0,
//             itemBuilder: (context, index) {
//               final int qNo = start + index;
//               return Container(
//                 padding: EdgeInsets.symmetric(vertical: s(6)),
//                 decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.5)))),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     SizedBox(width: s(30), child: Text(qNo.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: s(10)))),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: options.map((opt) {
//                         return Container(
//                           margin: EdgeInsets.symmetric(horizontal: s(6)),
//                           child: Column(
//                             children: [
//                               Text(opt, style: TextStyle(fontSize: s(12))),
//                               SizedBox(height: s(4)),
//                               Container(width: s(20), height: s(20), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: s(0.8)))),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildRightPanel() {
//     return Container(
//       decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.black, width: s(0.8)))),
//       child: Column(
//         children: [
//           Container(padding: EdgeInsets.all(s(8)), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.8)))), child: Text('প্রাপ্ত নম্বর', style: TextStyle(fontSize: s(12)))),
//           ...List.generate(16, (i) => Container(height: s(28), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: s(0.5)))), child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: s(10)))))),
//           Container(padding: EdgeInsets.all(s(8)), child: Column(children: [Text('প্রাপ্ত নম্বর\n(সংখ্যায়)', style: TextStyle(fontSize: s(10))), SizedBox(height: s(8)), Text('প্রাপ্ত নম্বর\n(কথায়)', style: TextStyle(fontSize: s(10))), SizedBox(height: s(8)), Text('সংশোধিত\nপ্রাপ্ত নম্বর', style: TextStyle(fontSize: s(10))), SizedBox(height: s(8)), Text('পূর্ণমান', style: TextStyle(fontSize: s(10)))])),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFooter() {
//     return Container(
//       padding: EdgeInsets.all(s(8)),
//       child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text('কক্ষ নং: ${config.roomNumber}', style: TextStyle(fontSize: s(10))), Text('বিভাগ: ${config.department}', style: TextStyle(fontSize: s(10))), Text('বিষয়: ${config.subjectName}', style: TextStyle(fontSize: s(10))), Text('পত্র: ', style: TextStyle(fontSize: s(10))), Text('শাখা: ${config.branch}', style: TextStyle(fontSize: s(10)))]),
//     );
//   }
// }
//
// // ------------------
// // PDF-side widget builder. This mirrors the on-screen sheet but builds using pdf widgets
// // and respects the `scale` parameter which maps PDF points to layout sizes.
// // ------------------
//
// class _PdfOMRSheet extends pw.StatelessWidget {
//   final OMRExamConfigg config;
//   final double scale;
//   final Size pageSize;
//
//   _PdfOMRSheet({
//     required this.config,
//     required this.scale,
//     required this.pageSize,
//   });
//
//   double s(double points) => points * scale;
//
//   @override
//   pw.Widget build(pw.Context context) {
//     return pw.Padding(
//       padding: pw.EdgeInsets.all(s(8)),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.stretch,
//         children: [
//           _pdfHeader(),
//           pw.SizedBox(height: s(8)),
//           _pdfTopSection(),
//           pw.SizedBox(height: s(8)),
//           _pdfStudentInfoSection(),
//           pw.SizedBox(height: s(8)),
//           pw.Expanded(child: _pdfAnswerSection()),
//           pw.SizedBox(height: s(8)),
//           _pdfFooter(),
//         ],
//       ),
//     );
//   }
//
//   // ---------------- HEADER ----------------
//   pw.Widget _pdfHeader() {
//     return pw.Container(
//       height: s(72),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.center,
//         children: [
//           pw.Container(
//             width: s(60),
//             height: s(60),
//             decoration: pw.BoxDecoration(
//               shape: pw.BoxShape.circle,
//               border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//             ),
//             child: pw.Center(
//               child: pw.Text(
//                 'LOGO',
//                 style: pw.TextStyle(fontSize: s(12)),
//               ),
//             ),
//           ),
//           pw.SizedBox(width: s(16)),
//           pw.Column(
//             mainAxisAlignment: pw.MainAxisAlignment.center,
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 config.examName,
//                 style: pw.TextStyle(
//                   fontSize: s(18),
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//               pw.SizedBox(height: s(6)),
//               pw.Container(
//                 padding:
//                 pw.EdgeInsets.symmetric(horizontal: s(14), vertical: s(6)),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//                 ),
//                 child: pw.Text(
//                   'কোড নং',
//                   style: pw.TextStyle(fontSize: s(12)),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------- TOP SECTION ----------------
//   pw.Widget _pdfTopSection() {
//     return pw.Column(
//       children: [
//         _pdfBubbleRow(),
//         pw.SizedBox(height: s(8)),
//         pw.Container(
//           padding: pw.EdgeInsets.all(s(8)),
//           decoration: pw.BoxDecoration(
//             border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//           ),
//           child: pw.Text(
//             'অবশ্যই কালো কালির বল পয়েন্ট কলম দিয়ে পূর্ণ ভরাট করতে হবে',
//             style: pw.TextStyle(
//               fontSize: s(12),
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   pw.Widget _pdfBubbleRow() {
//     const int bubbleCount = 30;
//     return pw.Container(
//       height: s(40),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//       ),
//       child: pw.Row(
//         children: List.generate(
//           bubbleCount,
//               (i) => pw.Container(
//             width: s(25),
//             height: s(40),
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 right: pw.BorderSide(color: PdfColors.black, width: s(0.5)),
//               ),
//             ),
//             child: pw.Center(
//               child: pw.Container(
//                 width: s(18),
//                 height: s(18),
//                 decoration: pw.BoxDecoration(
//                   shape: pw.BoxShape.circle,
//                   border:
//                   pw.Border.all(color: PdfColors.black, width: s(1.0)),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ---------------- STUDENT INFO ----------------
//   pw.Widget _pdfStudentInfoSection() {
//     final List<String> subjects = [
//       'প্রথম মেয়াদ',
//       'দ্বিতীয় মেয়াদ',
//       'অর্ধ-বার্ষিক',
//       'বার্ষিক',
//       'প্রাক-নির্বাচনী',
//       'নির্বাচনী',
//       'প্রস্তুতি মূল্যায়ন',
//       'মডেল টেস্ট',
//     ];
//
//     return pw.Container(
//       padding: pw.EdgeInsets.all(s(6)),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//       ),
//       child: pw.Column(
//         children: [
//           pw.Container(
//             padding: pw.EdgeInsets.all(s(4)),
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 bottom: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//               ),
//             ),
//             child: pw.Row(
//               children: [
//                 _pdfHeaderCell('পরীক্ষা', flex: 1),
//                 _pdfHeaderCell('রোল নম্বর', flex: 2),
//                 _pdfHeaderCell('রেজিস্ট্রেশন নম্বর', flex: 2),
//                 _pdfHeaderCell('বিষয় কোড', flex: 1),
//                 _pdfHeaderCell('সেট কোড', flex: 1),
//                 _pdfHeaderCell('পরীক্ষার্থীর স্বাক্ষর', flex: 2),
//               ],
//             ),
//           ),
//           pw.SizedBox(height: s(6)),
//           pw.Column(
//             children: subjects.map((sub) => _pdfSubjectRow(sub)).toList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   pw.Widget _pdfHeaderCell(String text, {int flex = 1}) {
//     return pw.Expanded(
//       flex: flex,
//       child: pw.Container(
//         padding: pw.EdgeInsets.all(s(3)),
//         decoration: pw.BoxDecoration(
//           border: pw.Border(
//             left: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//           ),
//         ),
//         child: pw.Text(text, style: pw.TextStyle(fontSize: s(10))),
//       ),
//     );
//   }
//
//   pw.Widget _pdfSubjectRow(String title) {
//     return pw.Container(
//       height: s(32),
//       decoration: pw.BoxDecoration(
//         border: pw.Border(
//           bottom: pw.BorderSide(color: PdfColors.black, width: s(0.5)),
//         ),
//       ),
//       child: pw.Row(
//         children: [
//           pw.Container(
//             width: s(20),
//             height: s(30),
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 right: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//               ),
//             ),
//             child: pw.Center(
//               child: pw.Container(
//                 width: s(14),
//                 height: s(14),
//                 decoration: pw.BoxDecoration(
//                   shape: pw.BoxShape.circle,
//                   border: pw.Border.all(color: PdfColors.black, width: s(0.9)),
//                 ),
//               ),
//             ),
//           ),
//           pw.Container(
//             width: s(100),
//             padding: pw.EdgeInsets.symmetric(horizontal: s(6)),
//             child: pw.Text(title, style: pw.TextStyle(fontSize: s(10))),
//           ),
//           ...List.generate(10, (i) {
//             return pw.Container(
//               width: s(25),
//               height: s(30),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border(
//                   right:
//                   pw.BorderSide(color: PdfColors.black, width: s(0.5)),
//                 ),
//               ),
//               child: pw.Center(
//                 child: pw.Column(
//                   mainAxisAlignment: pw.MainAxisAlignment.center,
//                   children: [
//                     pw.Text(i.toString(),
//                         style: pw.TextStyle(fontSize: s(8))),
//                     pw.SizedBox(height: s(2)),
//                     pw.Container(
//                       width: s(14),
//                       height: s(14),
//                       decoration: pw.BoxDecoration(
//                         shape: pw.BoxShape.circle,
//                         border:
//                         pw.Border.all(color: PdfColors.black, width: s(0.8)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//           pw.Expanded(
//             child: pw.Container(
//               height: s(30),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border(
//                   left: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------- ANSWER SECTION ----------------
//   pw.Widget _pdfAnswerSection() {
//     return pw.Container(
//       padding: pw.EdgeInsets.all(s(6)),
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//       ),
//       child: pw.Row(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Expanded(flex: 2, child: _pdfSignatureSection()),
//           pw.SizedBox(width: s(8)),
//           pw.Expanded(flex: 6, child: _pdfAnswerBubbles()),
//           pw.SizedBox(width: s(8)),
//           pw.Expanded(flex: 2, child: _pdfMarksSection()),
//         ],
//       ),
//     );
//   }
//
//   pw.Widget _pdfSignatureSection() {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text('পরীক্ষকের স্বাক্ষর ও তারিখ', style: pw.TextStyle(fontSize: s(10))),
//         pw.SizedBox(height: s(24)),
//         pw.Text('নির্দেশকের স্বাক্ষর ও তারিখ', style: pw.TextStyle(fontSize: s(10))),
//         pw.SizedBox(height: s(24)),
//         pw.Text('তত্ত্বাবধায়কের স্বাক্ষর ও তারিখ', style: pw.TextStyle(fontSize: s(10))),
//         pw.SizedBox(height: s(24)),
//         pw.Container(
//           width: s(100),
//           height: s(100),
//           decoration: pw.BoxDecoration(
//             shape: pw.BoxShape.circle,
//             border: pw.Border.all(color: PdfColors.black, width: s(1.0)),
//           ),
//           child: pw.Center(
//             child: pw.Text('কলেজের সীলমোহর',
//                 textAlign: pw.TextAlign.center,
//                 style: pw.TextStyle(fontSize: s(8))),
//           ),
//         ),
//       ],
//     );
//   }
//
//   pw.Widget _pdfAnswerBubbles() {
//     final int total = config.totalQuestions;
//     final int cols = config.columns > 0 ? config.columns : 3;
//     final int perColumn = (total / cols).ceil();
//
//     return pw.Container(
//       decoration: pw.BoxDecoration(
//         border: pw.Border.all(color: PdfColors.black, width: s(0.8)),
//       ),
//       child: pw.Row(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: List.generate(cols, (colIndex) {
//           final int start = colIndex * perColumn + 1;
//           final int end = ((colIndex + 1) * perColumn).clamp(0, total);
//           return pw.Expanded(child: _pdfQuestionColumn(start, end));
//         }),
//       ),
//     );
//   }
//
//   pw.Widget _pdfQuestionColumn(int start, int end) {
//     final List<String> options = ['ক', 'খ', 'গ', 'ঘ'];
//
//     return pw.Column(
//       children: [
//         pw.Container(
//           padding: pw.EdgeInsets.all(s(6)),
//           decoration: pw.BoxDecoration(
//             border: pw.Border(
//               bottom: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//             ),
//           ),
//           child: pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
//             children: [
//               pw.Text('প্রশ্ন\nনম্বর', style: pw.TextStyle(fontSize: s(10))),
//               pw.Text('উত্তর', style: pw.TextStyle(fontSize: s(10))),
//             ],
//           ),
//         ),
//         ...List.generate((end - start + 1), (index) {
//           final int qNo = start + index;
//           return pw.Container(
//             padding: pw.EdgeInsets.symmetric(vertical: s(6)),
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 bottom: pw.BorderSide(color: PdfColors.black, width: s(0.5)),
//               ),
//             ),
//             child: pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
//               children: [
//                 pw.SizedBox(
//                   width: s(30),
//                   child: pw.Text(
//                     qNo.toString(),
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(fontSize: s(10)),
//                   ),
//                 ),
//                 pw.Row(
//                   children: options
//                       .map(
//                         (opt) => pw.Container(
//                       margin:
//                       pw.EdgeInsets.symmetric(horizontal: s(6)),
//                       child: pw.Column(
//                         children: [
//                           pw.Text(opt, style: pw.TextStyle(fontSize: s(12))),
//                           pw.SizedBox(height: s(4)),
//                           pw.Container(
//                             width: s(20),
//                             height: s(20),
//                             decoration: pw.BoxDecoration(
//                               shape: pw.BoxShape.circle,
//                               border: pw.Border.all(
//                                   color: PdfColors.black, width: s(0.8)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                       .toList(),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ],
//     );
//   }
//
//   pw.Widget _pdfMarksSection() {
//     return pw.Container(
//       decoration: pw.BoxDecoration(
//         border: pw.Border(
//           left: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//         ),
//       ),
//       child: pw.Column(
//         children: [
//           pw.Container(
//             padding: pw.EdgeInsets.all(s(8)),
//             decoration: pw.BoxDecoration(
//               border: pw.Border(
//                 bottom: pw.BorderSide(color: PdfColors.black, width: s(0.8)),
//               ),
//             ),
//             child:
//             pw.Text('প্রাপ্ত নম্বর', style: pw.TextStyle(fontSize: s(12))),
//           ),
//           ...List.generate(
//             16,
//                 (i) => pw.Container(
//               height: s(28),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border(
//                   bottom: pw.BorderSide(color: PdfColors.black, width: s(0.5)),
//                 ),
//               ),
//               child: pw.Center(
//                 child: pw.Text('${i + 1}', style: pw.TextStyle(fontSize: s(10))),
//               ),
//             ),
//           ),
//           pw.Container(
//             padding: pw.EdgeInsets.all(s(8)),
//             child: pw.Column(
//               children: [
//                 pw.Text('প্রাপ্ত নম্বর\n(সংখ্যায়)',
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(fontSize: s(10))),
//                 pw.SizedBox(height: s(8)),
//                 pw.Text('প্রাপ্ত নম্বর\n(কথায়)',
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(fontSize: s(10))),
//                 pw.SizedBox(height: s(8)),
//                 pw.Text('সংশোধিত\nপ্রাপ্ত নম্বর',
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(fontSize: s(10))),
//                 pw.SizedBox(height: s(8)),
//                 pw.Text('পূর্ণমান',
//                     textAlign: pw.TextAlign.center,
//                     style: pw.TextStyle(fontSize: s(10))),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ---------------- FOOTER ----------------
//   pw.Widget _pdfFooter() {
//     return pw.Container(
//       padding: pw.EdgeInsets.all(s(8)),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
//         children: [
//           pw.Text('কক্ষ নং: ${config.roomNumber}',
//               style: pw.TextStyle(fontSize: s(10))),
//           pw.Text('বিভাগ: ${config.department}',
//               style: pw.TextStyle(fontSize: s(10))),
//           pw.Text('বিষয়: ${config.subjectName}',
//               style: pw.TextStyle(fontSize: s(10))),
//           pw.Text('পত্র: ', style: pw.TextStyle(fontSize: s(10))),
//           pw.Text('শাখা: ${config.branch}',
//               style: pw.TextStyle(fontSize: s(10))),
//         ],
//       ),
//     );
//   }
// }
