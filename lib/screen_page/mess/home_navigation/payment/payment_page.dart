import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PaymentPageState();
  }
}

class PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.deepPurple[100],
              backgroundImage: AssetImage('assets/background.jpg'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.deepPurple.shade100,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16),
              FeeForm(),
              FeeTable(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class FeeForm extends StatelessWidget {
  final TextEditingController _feeTypeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Fee',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _feeTypeController,
                decoration: InputDecoration(
                  labelText: 'Fee Type',
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  prefixIcon: Icon(Icons.category, color: Colors.deepPurple),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurple),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add fee logic here
                },
                child: Text(
                  'ADD FEE',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeeTable extends StatelessWidget {
  final List<Map<String, dynamic>> fees = [
    {'id': '1', 'type': 'Mess Fee', 'amount': '1500', 'date': 'Jan 15, 2023', 'status': 'Paid'},
    {'id': '2', 'type': 'Electricity', 'amount': '300', 'date': 'Feb 2, 2023', 'status': 'Pending'},
    {'id': '3', 'type': 'Water Bill', 'amount': '200', 'date': 'Feb 5, 2023', 'status': 'Paid'},
    {'id': '4', 'type': 'Extra', 'amount': '50', 'date': 'Feb 10, 2023', 'status': 'Overdue'},
  ];

  @override
  Widget build(BuildContext context) {
    final totalAmount = fees.fold(0, (sum, fee) => sum + int.parse(fee['amount']));

    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fee History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.deepPurple),
                    onPressed: () {
                      // Filter functionality
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dividerThickness: 0,
                    dataRowHeight: 60,
                    headingRowHeight: 50,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    columns: [
                      DataColumn(
                        label: _TableHeader('ID'),
                      ),
                      DataColumn(
                        label: _TableHeader('Fee Type'),
                      ),
                      DataColumn(
                        label: _TableHeader('Date'),
                      ),
                      DataColumn(
                        label: _TableHeader('Amount'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: _TableHeader('Status'),
                      ),
                      DataColumn(
                        label: _TableHeader('Action'),
                      ),
                    ],
                    rows: fees.map((fee) {
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            return states.contains(MaterialState.selected)
                                ? Colors.deepPurple.withOpacity(0.1)
                                : Colors.transparent;
                          },
                        ),
                        cells: [
                          DataCell(Text(fee['id'])),
                          DataCell(
                            Text(
                              fee['type'],
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          DataCell(Text(fee['date'])),
                          DataCell(
                            Text(
                              '\$${fee['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(fee['status']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                fee['status'],
                                style: TextStyle(
                                  color: _getStatusColor(fee['status']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.more_vert, size: 20),
                              onPressed: () {
                                _showOptions(context, fee['id']);
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      '\$$totalAmount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOptions(BuildContext context, String feeId) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.receipt, color: Colors.deepPurple),
                title: Text('View Receipt'),
                onTap: () {
                  Navigator.pop(context);
                  // View receipt logic
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.deepPurple),
                title: Text('Edit Fee'),
                onTap: () {
                  Navigator.pop(context);
                  // Edit logic
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Delete logic
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
        fontSize: 14,
      ),
    );
  }
}