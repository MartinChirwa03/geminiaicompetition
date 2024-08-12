import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:excel/excel.dart';

abstract class IPMRecord {
  int? id;
  String date;
  String pest;
  String disease;
  String treatment;
  String effectiveness;

  IPMRecord({
    this.id,
    required this.date,
    required this.pest,
    required this.disease,
    required this.treatment,
    required this.effectiveness,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'pest': pest,
      'disease': disease,
      'treatment': treatment,
      'effectiveness': effectiveness,
    };
  }
}

class IPMRecordData extends IPMRecord {
  IPMRecordData({
    int? id,
    required String date,
    required String pest,
    required String disease,
    required String treatment,
    required String effectiveness,
  }) : super(
    id: id,
    date: date,
    pest: pest,
    disease: disease,
    treatment: treatment,
    effectiveness: effectiveness,
  );

  factory IPMRecordData.fromMap(Map<String, dynamic> map) {
    return IPMRecordData(
      id: map['id'],
      date: map['date'],
      pest: map['pest'],
      disease: map['disease'],
      treatment: map['treatment'],
      effectiveness: map['effectiveness'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ipm_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ipm_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        pest TEXT,
        disease TEXT,
        treatment TEXT,
        effectiveness TEXT
      )
    ''');
  }

  Future<int> insertRecord(IPMRecordData record) async {
    final db = await instance.database;
    return await db.insert('ipm_records', record.toMap());
  }

  Future<List<IPMRecordData>> getRecords() async {
    final db = await instance.database;
    final maps = await db.query('ipm_records', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => IPMRecordData.fromMap(maps[i]));
  }

  Future<int> updateRecord(IPMRecordData record) async {
    final db = await instance.database;
    return await db.update(
      'ipm_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'ipm_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> exportToExcel(List<IPMRecordData> records) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Pest'),
      TextCellValue('Disease'),
      TextCellValue('Treatment'),
      TextCellValue('Effectiveness'),
    ]);

    // Add data
    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record.date.toString()),
        TextCellValue(record.pest.toString()),
        TextCellValue(record.disease.toString()),
        TextCellValue(record.treatment.toString()),
        TextCellValue(record.effectiveness.toString()),
      ]);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/ipm_records.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } else {
      print('Failed to encode Excel file');
    }
  }

  Future<void> exportToPdf(List<IPMRecordData> records) async {
    final pdf = pw.Document();

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          pw.Header(level: 0, child: pw.Text('Pest and Management Records'));
          return pw.Table.fromTextArray(
            data: <List<String>>[
              <String>['Date', 'Pest', 'Disease', 'Treatment', 'Effectiveness'],
              ...records.map((record) => [
                record.date,
                record.pest,
                record.disease,
                record.treatment,
                record.effectiveness,
              ]),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/ipm_records.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}

class IPMPage extends StatefulWidget {
  @override
  _IPMPageState createState() => _IPMPageState();
}

class _IPMPageState extends State<IPMPage> {
  List<IPMRecordData> records = [];
  List<ChartData> chartData = [];
  bool showChart = false;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final fetchedRecords = await DatabaseHelper.instance.getRecords();
    setState(() {
      records = fetchedRecords;
      _generateChartData(fetchedRecords);
    });
  }

  Future<void> _showRecordDialog(BuildContext context, IPMRecordData? record) async {
    final isEditing = record != null;
    final dateController = TextEditingController(
        text: isEditing ? record!.date : DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final pestController = TextEditingController(text: isEditing ? record!.pest : '');
    final diseaseController =
    TextEditingController(text: isEditing ? record!.disease : '');
    final treatmentController =
    TextEditingController(text: isEditing ? record!.treatment : '');
    final effectivenessController =
    TextEditingController(text: isEditing ? record!.effectiveness : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit IPM Record' : 'Add IPM Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date'),
              ),
              TextField(
                controller: pestController,
                decoration: InputDecoration(labelText: 'Pest'),
              ),
              TextField(
                controller: diseaseController,
                decoration: InputDecoration(labelText: 'Disease'),
              ),
              TextField(
                controller: treatmentController,
                decoration: InputDecoration(labelText: 'Treatment'),
              ),
              TextField(
                controller: effectivenessController,
                decoration: InputDecoration(labelText: 'Effectiveness'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newRecord = IPMRecordData(
                id: isEditing ? record!.id : null,
                date: dateController.text,
                pest: pestController.text,
                disease: diseaseController.text,
                treatment: treatmentController.text,
                effectiveness: effectivenessController.text,
              );

              if (isEditing) {
                await DatabaseHelper.instance.updateRecord(newRecord);
              } else {
                await DatabaseHelper.instance.insertRecord(newRecord);
              }

              Navigator.pop(context);
              _refreshRecords();
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _generateChartData(List<IPMRecordData> records) {
    Map<String, int> pestCount = {};
    for (final record in records) {
      pestCount[record.pest] = (pestCount[record.pest] ?? 0) + 1;
    }
    chartData = pestCount.entries.map((entry) {
      return ChartData(entry.key, entry.value);
    }).toList();
  }

  void _toggleChart() {
    setState(() {
      showChart = !showChart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Entomology',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _showRecordDialog(context, null),
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.green),
            onPressed: () async {
              final records = await DatabaseHelper.instance.getRecords();
              await DatabaseHelper.instance.exportToPdf(records);
            },
          ),
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.orangeAccent),
            onPressed: _toggleChart,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/_6c24f81a-0713-4130-b9a1-56d27a08b104.jpeg'), // Your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Add a Container to control the chart's visibility and appearance
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: showChart ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Container(
                height: 300,
                color: Colors.black.withOpacity(0.5), // Chart background
                child: SfCircularChart(

                  title: ChartTitle(text: 'Pest Occurrences', textStyle: TextStyle(color: Colors.white)),
                  legend: Legend(isVisible: true, textStyle: TextStyle(color: Colors.white)),
                  series: <CircularSeries>[
                    PieSeries<ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.category,
                      yValueMapper: (ChartData data, _) => data.count,
                      dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: showChart ? 300 : 0), // Adjust the margin based on the chart height
            color: Colors.black.withOpacity(0.5), // Make the background slightly transparent for contrast
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return ListTile(
                        title: Text('${record.pest} - ${record.disease}', style: TextStyle(color: Colors.white)),
                        subtitle: Text(record.date, style: TextStyle(color: Colors.white)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showRecordDialog(context, record),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteRecord(record.id!);
                                _refreshRecords();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.file_download, color: Colors.white),
        onPressed: () async {
          final records = await DatabaseHelper.instance.getRecords();
          await DatabaseHelper.instance.exportToExcel(records);
        },
      ),
    );
  }
}

class ChartData {
  ChartData(this.category, this.count);
  final String category;
  final int count;
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      primaryColor: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.blueGrey,
    ),
    home: IPMPage(),
  ));
}