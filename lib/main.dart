import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'expense.dart';
import 'database_helper.dart';


void main() {
  runApp(ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExpenseListScreen(),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late DatabaseHelper dbHelper;
  List<Expense> expenses = [];
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await dbHelper.getExpenses();
    double total = data.fold(0.0, (sum, item) => sum + item.amount);
    setState(() {
      expenses = data;
      totalExpense = total;
    });
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen()),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  void _navigateToEditExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  void _deleteExpense(int id) async {
    await dbHelper.deleteExpense(id);
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expenses')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ListTile(
                  title: Text(expense.title),
                  subtitle: Text('${expense.category} - \$${expense.amount.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _navigateToEditExpense(expense),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteExpense(expense.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Expense:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalExpense.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: FloatingActionButton(
          onPressed: _navigateToAddExpense,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  AddExpenseScreen({this.expense});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _category;
  late double _amount;
  late DateTime _date;
  late DatabaseHelper dbHelper;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _title = widget.expense?.title ?? '';
    _category = widget.expense?.category ?? '';
    _amount = widget.expense?.amount ?? 0.0;
    _date = widget.expense?.date ?? DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_date);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _date)
      setState(() {
        _date = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_date);
      });
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final expense = Expense(
        id: widget.expense?.id,
        title: _title,
        category: _category,
        amount: _amount,
        date: _date,
      );
      if (widget.expense == null) {
        await dbHelper.insertExpense(expense);
      } else {
        await dbHelper.updateExpense(expense);
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (value) {
                  _title = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _category,
                decoration: InputDecoration(labelText: 'Category'),
                onSaved: (value) {
                  _category = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _amount != 0.0 ? _amount.toString() : '',
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _amount = double.parse(value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text(widget.expense == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
