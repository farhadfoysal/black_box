import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../model/mess/bazar_list.dart';
import '../../../../model/mess/mess_main.dart';
import '../../../../model/mess/mess_user.dart';

class BazarExpenseListPage extends StatefulWidget {
  final List<MessUser> users;
  final List<BazarList> bazarLists;
  final MessMain messInfo;

  const BazarExpenseListPage({
    Key? key,
    required this.users,
    required this.bazarLists,
    required this.messInfo,
  }) : super(key: key);

  @override
  _BazarExpenseListPageState createState() => _BazarExpenseListPageState();
}

class _BazarExpenseListPageState extends State<BazarExpenseListPage> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  final Color _primaryColor = const Color(0xFF6C5CE7);
  final Color _secondaryColor = const Color(0xFFA29BFE);
  final Color _accentColor = const Color(0xFFFD79A8);
  final Color _backgroundColor = const Color(0xFFF5F6FA);
  final Color _textColor = const Color(0xFF2D3436);

  @override
  Widget build(BuildContext context) {
    // Group bazar lists by user
    final Map<String, List<BazarList>> userBazarMap = {};
    for (var bazar in widget.bazarLists) {
      if (!userBazarMap.containsKey(bazar.phone)) {
        userBazarMap[bazar.phone] = [];
      }
      userBazarMap[bazar.phone]!.add(bazar);
    }

    // Calculate monthly totals
    final Map<String, double> monthlyTotals = {};
    for (var bazar in widget.bazarLists) {
      final monthKey = _monthFormat.format(bazar.dateTime as DateTime);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + double.parse(bazar.amount);
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.indigo.shade100,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade100,
                ),
                child: Icon(Icons.code_rounded,
                    size: 16,
                    color: Colors.indigo.shade800),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.indigo.shade800,
                  highlightColor: Colors.indigo.shade400,
                  child: Marquee(
                    text: "Bazar List",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade800,
                    ),
                    scrollAxis: Axis.horizontal,
                    blankSpace: 40.0,
                    velocity: 60.0,
                    pauseAfterRound: Duration(seconds: 2),
                    startPadding: 20.0,
                    accelerationDuration: Duration(seconds: 1),
                    decelerationDuration: Duration(milliseconds: 500),
                    fadingEdgeStartFraction: 0.1,
                    fadingEdgeEndFraction: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddBazarDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthlySummary(monthlyTotals),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.users.length,
              itemBuilder: (context, index) {
                final user = widget.users[index];
                final userBazars = userBazarMap[user.phone] ?? [];
                final totalAmount = userBazars.fold(
                    0.0, (sum, bazar) => sum + double.parse(bazar.amount));

                return _buildUserCard(user, userBazars, totalAmount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(Map<String, double> monthlyTotals) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
        BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Monthly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 12),
          ...monthlyTotals.entries.map((entry) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  '৳${entry.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUserCard(MessUser user, List<BazarList> bazarLists, double totalAmount) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _secondaryColor.withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: _primaryColor,
          ),
        ),
        title: Text(
          user.userId ?? 'Unknown User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              user.phone ?? 'No phone',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ৳${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: _primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => _showUserBazarDetails(user, bazarLists),
      ),
    );
  }

  void _showUserBazarDetails(MessUser user, List<BazarList> bazarLists) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bazar Details: ${user.userId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _showAddBazarDialog(user: user),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bazarLists.length,
                  itemBuilder: (context, index) {
                    final bazar = bazarLists[index];
                    return _buildBazarItem(bazar);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBazarItem(BazarList bazar) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '৳${bazar.amount}',
            style: TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        bazar.listDetails,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
      ),
      subtitle: Text(
        _dateFormat.format(bazar.dateTime as DateTime),
        style: TextStyle(
          color: _textColor.withOpacity(0.6),
        ),
      ),
      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: Colors.grey),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text('Edit'),
            value: 'edit',
          ),
          PopupMenuItem(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            value: 'delete',
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _showAddBazarDialog(bazar: bazar);
          } else if (value == 'delete') {
            _confirmDeleteBazar(bazar);
          }
        },
      ),
    );
  }

  void _showAddBazarDialog({MessUser? user, BazarList? bazar}) {
    final isEdit = bazar != null;
    final TextEditingController amountController = TextEditingController(
      text: isEdit ? bazar.amount : '',
    );
    final TextEditingController detailsController = TextEditingController(
      text: isEdit ? bazar.listDetails : '',
    );
    DateTime selectedDate = isEdit ? bazar.dateTime as DateTime : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? 'Edit Bazar' : 'Add New Bazar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                if (!isEdit && user == null)
                  DropdownButtonFormField<MessUser>(
                    decoration: InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.users
                        .map((user) => DropdownMenuItem(
                      value: user,
                      child: Text('${user.userId} (${user.phone})'),
                    ))
                        .toList(),
                    onChanged: (user) {},
                  ),
                SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '৳',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: detailsController,
                  decoration: InputDecoration(
                    labelText: 'Details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text(
                    'Date',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
                    ),
                  ),
                  subtitle: Text(
                    _dateFormat.format(selectedDate),
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: _primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: _textColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Update Bazar' : 'Add Bazar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    // Validate and save
                    if (amountController.text.isNotEmpty &&
                        detailsController.text.isNotEmpty) {
                      // Here you would save to your database
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Bazar ${isEdit ? 'updated' : 'added'} successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteBazar(BazarList bazar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bazar?'),
        content: Text('Are you sure you want to delete this bazar record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would delete from your database
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bazar deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}