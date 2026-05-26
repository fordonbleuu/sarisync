import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/sarisync_database.dart';
import '../design_system/sari_design_system.dart';

class AuditReportScreen extends StatefulWidget {
  const AuditReportScreen({super.key});

  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<SalesItem> _salesItems = [];
  Map<String, Product> _productMap = {};

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase.instance;
      final items = await db.getSalesItemsForDate(_selectedDate);
      final products = await db.getProductsForItems(items);
      final productMap = <String, Product>{};
      for (final p in products) {
        productMap[p.id] = p;
      }
      if (mounted) {
        setState(() {
          _salesItems = items;
          _productMap = productMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalSales {
    return _salesItems.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPriceAtSale));
  }

  void _navigateDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _loadSalesData();
  }

  void _goToToday() {
    setState(() => _selectedDate = DateTime.now());
    _loadSalesData();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadSalesData();
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final dateStr = dateFormat.format(_selectedDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('SariSync POS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Header(
              level: 1,
              child: pw.Text('Daily Sales Report', style: pw.TextStyle(fontSize: 18)),
            ),
            pw.Paragraph(text: 'Date: $dateStr'),
            pw.Divider(),
            pw.Header(level: 2, child: pw.Text('Sales Items')),
            pw.SizedBox(height: 8),
            if (_salesItems.isEmpty)
              pw.Paragraph(text: 'No sales for this day.')
            else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(30),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(70),
                3: const pw.FixedColumnWidth(40),
                4: const pw.FixedColumnWidth(70),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('#', isHeader: true),
                    _pdfCell('Product', isHeader: true),
                    _pdfCell('Price', isHeader: true),
                    _pdfCell('Qty', isHeader: true),
                    _pdfCell('Total', isHeader: true),
                  ],
                ),
                ...List.generate(_salesItems.length, (i) {
                  final item = _salesItems[i];
                  final product = _productMap[item.productId];
                  final lineTotal = item.quantity * item.unitPriceAtSale;
                  return pw.TableRow(
                    children: [
                      _pdfCell('${i + 1}'),
                      _pdfCell(product?.name ?? 'Unknown'),
                      _pdfCell(currencyFormat.format(item.unitPriceAtSale)),
                      _pdfCell('${item.quantity}'),
                      _pdfCell(currencyFormat.format(lineTotal)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Sales:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(currencyFormat.format(_totalSales),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue)),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Paragraph(
              text: 'Generated on ${DateFormat('MMM d, yyyy – h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'sales_report_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: SariGradients.appBar),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Color(0xFF1565C0)),
            ),
            onPressed: _salesItems.isNotEmpty ? _downloadPdf : null,
            tooltip: 'Download PDF',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.today, color: Color(0xFF1565C0)),
            ),
            onPressed: _goToToday,
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateNavigation(),
                Expanded(
                  child: _salesItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No sales for this day',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _salesItems.length + 1,
                          itemBuilder: (context, index) {
                            if (index < _salesItems.length) {
                              return _buildSalesItem(_salesItems[index]);
                            }
                            return _buildTotalSection();
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateNavigation() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SariColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigateDate(-1),
          ),
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isToday
                            ? 'Today'
                            : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : () => _navigateDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesItem(SalesItem item) {
    final product = _productMap[item.productId];
    final productName = product?.name ?? 'Unknown Product';
    final lineTotal = item.quantity * item.unitPriceAtSale;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SariColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${item.unitPriceAtSale.toStringAsFixed(2)} x ${item.quantity}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₱${lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SariColors.primaryGreen, SariColors.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SariColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Sales',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('for the day',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '₱${_totalSales.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
