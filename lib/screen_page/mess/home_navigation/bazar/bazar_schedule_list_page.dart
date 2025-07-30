import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../model/mess/mess_main.dart';
import '../../../../model/mess/mess_user.dart';

class BazarScheduleListPage extends StatefulWidget {
  final List<MessUser> users;
  final MessMain messInfo;

  const BazarScheduleListPage({
    Key? key,
    required this.users,
    required this.messInfo,
  }) : super(key: key);

  @override
  _BazarScheduleListPageState createState() => _BazarScheduleListPageState();
}

class _BazarScheduleListPageState extends State<BazarScheduleListPage> {
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  final Color _primaryColor = const Color(0xFF6C5CE7);
  final Color _secondaryColor = const Color(0xFFA29BFE);
  final Color _accentColor = const Color(0xFFFD79A8);
  final Color _backgroundColor = const Color(0xFFF5F6FA);
  final Color _textColor = const Color(0xFF2D3436);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Bazar Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              // Add calendar view functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMessInfoCard(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.users.length,
              itemBuilder: (context, index) {
                final user = widget.users[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _addNewBazarSchedule,
      ),
    );
  }

  Widget _buildMessInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.messInfo.messName ?? 'Mess Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.messInfo.messAddress ?? 'Mess Address',
            style: TextStyle(
              fontSize: 14,
              color: _textColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[300]),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                icon: Icons.people,
                label: 'Total Members',
                value: widget.users.length.toString(),
              ),
              _buildInfoItem(
                icon: Icons.date_range,
                label: 'Current Month',
                value: widget.messInfo.currentMonth ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: _secondaryColor),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _textColor.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(MessUser user) {
    final hasSchedule = user.bazarStart != null && user.bazarEnd != null;
    final isCurrent = hasSchedule &&
        DateTime.now().isAfter(user.bazarStart!) &&
        DateTime.now().isBefore(user.bazarEnd!);

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
            if (hasSchedule)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? _accentColor.withOpacity(0.2)
                      : _secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isCurrent ? _accentColor : _secondaryColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${_dateFormat.format(user.bazarStart!)} - ${_dateFormat.format(user.bazarEnd!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? _accentColor : _secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isCurrent) ...[
                      SizedBox(width: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (!hasSchedule)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'No schedule assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: _primaryColor),
                      title: Text('Edit Schedule'),
                      onTap: () {
                        Navigator.pop(context);
                        _assignBazarSchedule(user);
                      },
                    ),
                    if (user.bazarStart != null)
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Reset Schedule', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _resetBazarSchedule(user);
                        },
                      ),
                    ListTile(
                      leading: Icon(Icons.close),
                      title: Text('Cancel'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _assignBazarSchedule(MessUser user) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: user.bazarStart != null && user.bazarEnd != null
          ? DateTimeRange(start: user.bazarStart!, end: user.bazarEnd!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textColor,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        user.bazarStart = pickedDateRange.start;
        user.bazarEnd = pickedDateRange.end;
      });

      // Here you would typically call your API to save the changes
      // await _updateUserBazarSchedule(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bazar schedule updated for ${user.userId}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

// Method to reset bazar schedule
  Future<void> _resetBazarSchedule(MessUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Schedule?'),
        content: Text(
            'Are you sure you want to remove the bazar schedule for ${user.userId}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: _textColor))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        user.bazarStart = null;
        user.bazarEnd = null;
      });

      // Here you would typically call your API to save the changes
      // await _updateUserBazarSchedule(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bazar schedule reset for ${user.userId}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

// Method to handle the floating action button press
  void _addNewBazarSchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Assign New Bazar Schedule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<MessUser>(
                  decoration: InputDecoration(
                    labelText: 'Select User',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.users
                      .where((user) => user.bazarStart == null)
                      .map((user) => DropdownMenuItem(
                            value: user,
                            child: Text('${user.userId} (${user.phone})'),
                          ))
                      .toList(),
                  onChanged: (user) {
                    if (user != null) {
                      Navigator.pop(context);
                      _assignBazarSchedule(user);
                    }
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
