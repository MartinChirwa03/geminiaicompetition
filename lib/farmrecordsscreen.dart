import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class FarmRecord {
  int? id;
  String date;
  String crop;
  String activity;
  String notes;
  double? price;

  FarmRecord({
    this.id,
    required this.date,
    required this.crop,
    required this.activity,
    required this.notes,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'crop': crop,
      'activity': activity,
      'notes': notes,
      'price': price,
    };
  }

  factory FarmRecord.fromMap(Map<String, dynamic> map) {
    return FarmRecord(
      id: map['id'],
      date: map['date'],
      crop: map['crop'],
      activity: map['activity'],
      notes: map['notes'],
      price: map['price'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farm_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE farm_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        crop TEXT,
        activity TEXT,
        notes TEXT,
        price REAL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE farm_records ADD COLUMN price REAL');
    }
  }

  Future<int> insertRecord(FarmRecord record) async {
    final db = await instance.database;
    return await db.insert('farm_records', record.toMap());
  }

  Future<List<FarmRecord>> getRecords() async {
    final db = await instance.database;
    final maps = await db.query('farm_records', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => FarmRecord.fromMap(maps[i]));
  }

  Future<int> updateRecord(FarmRecord record) async {
    final db = await instance.database;
    return await db.update(
      'farm_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'farm_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class FarmRecordsScreen extends StatefulWidget {
  @override
  _FarmRecordsScreenState createState() => _FarmRecordsScreenState();
}

class _FarmRecordsScreenState extends State<FarmRecordsScreen> {
  List<FarmRecord> records = [];

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final fetchedRecords = await DatabaseHelper.instance.getRecords();
    setState(() {
      records = fetchedRecords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Farm Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf,
              color: Colors.green,
            ),
            onPressed: _generatePDF,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/_2930b917-e7ba-4962-85b7-0059c96271d0.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                title: Text(
                  record.crop,
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${record.date} - ${record.activity} - \K${record.price?.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteRecord(record.id!);
                    _refreshRecords();
                  },
                ),
                onTap: () => _showRecordDialog(context, record),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showRecordDialog(context, null),
      ),
    );
  }

  Future<void> _showRecordDialog(BuildContext context, FarmRecord? record) async {
    final isEditing = record != null;
    final titleController = TextEditingController(text: isEditing ? record?.crop : '');
    final activityController = TextEditingController(text: isEditing ? record?.activity : '');
    final notesController = TextEditingController(text: isEditing ? record?.notes : '');
    final priceController = TextEditingController(text: isEditing ? record?.price?.toString() : '');
    String selectedDate = isEditing ? record!.date : DateFormat('yyyy-MM-dd').format(DateTime.now());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Record' : 'Add Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Crop'),
              ),
              TextField(
                controller: activityController,
                decoration: InputDecoration(labelText: 'Activity'),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                child: Text('Select Date'),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(selectedDate),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () async {
              try {
                if (titleController.text.isEmpty ||
                    activityController.text.isEmpty ||
                    notesController.text.isEmpty ||
                    selectedDate.isEmpty) {
                  print('Please fill all the fields');
                  return;
                }

                final newRecord = FarmRecord(
                  id: isEditing ? record?.id : null,
                  date: selectedDate,
                  crop: titleController.text,
                  activity: activityController.text,
                  notes: notesController.text,
                  price: double.tryParse(priceController.text),
                );

                if (isEditing) {
                  print('Updating record: ${newRecord.toMap()}');
                  await DatabaseHelper.instance.updateRecord(newRecord);
                } else {
                  print('Inserting record: ${newRecord.toMap()}');
                  await DatabaseHelper.instance.insertRecord(newRecord);
                }

                Navigator.pop(context);
                _refreshRecords();
              } catch (e) {
                print('Error: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context pdfContext) => [
          pw.Header(level: 0, child: pw.Text('Farm Records Report')),
          pw.Table.fromTextArray(
            context: pdfContext,
            data: <List<String>>[
              <String>['Date', 'Crop', 'Activity', 'Notes', 'Price (Kwacha)'],
              ...records.map((record) => [
                record.date,
                record.crop,
                record.activity,
                record.notes,
                record.price?.toStringAsFixed(2) ?? 'N/A',
              ]),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/farm_records.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);
  }
}

void main() {
  runApp(MaterialApp(
    home: FarmRecordsScreen(),
  ));
}
