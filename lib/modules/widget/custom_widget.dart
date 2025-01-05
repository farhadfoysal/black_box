
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget _buildTextField(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}

Widget _buildTimePickUpField(BuildContext context,String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      readOnly: true, // Makes the field non-editable
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(), // Set the initial time to now
        );

        if (pickedTime != null) {
          final localizations = MaterialLocalizations.of(context);
          String formattedTime = localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: false);

          // Set the selected time into the controller
          controller.text = formattedTime;
        }
      },
    ),
  );
}

Widget _buildIntSelectionDropdown(int selectedValue, ValueChanged<int?> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<int>(
      value: selectedValue,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: 'Select Route Type',
        suffixIcon: Icon(Icons.directions),
      ),
      items: [
        DropdownMenuItem<int>(
          value: 0,
          child: Text('Only Location -> Destination'),
        ),
        DropdownMenuItem<int>(
          value: 1,
          child: Text('Both Location <-> Destination'),
        ),
      ],
    ),
  );
}

Widget _buildIntSelectionRadio(int selectedValue, ValueChanged<int?> onChanged) {
  return Column(
    children: [
      RadioListTile<int>(
        title: const Text('Only Location -> Destination'),
        value: 0,
        groupValue: selectedValue,
        onChanged: onChanged,
      ),
      RadioListTile<int>(
        title: const Text('Both Location <-> Destination'),
        value: 1,
        groupValue: selectedValue,
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _buildPhoneField(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.phone, // Set keyboard for phone input
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Restrict to digits only
      ],
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}

Widget _buildSelectionField({
  required String selectedRoomType,
  required String labelText,
  required IconData icon,
  required TextEditingController controller,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<String>(
      value: selectedRoomType,
      hint: Text(labelText),
      icon: Icon(icon),
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
      ),
      items: <String>['Theory Room', 'Lab Room'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {

        // setState(() {
        //   // _selectedRoomType = newValue;
        //   controller.text = newValue ?? '';
        // });
      },
    ),
  );
}


Widget _buildYearSelectDropdownField(String labelText, IconData icon, String? selectedYear, ValueChanged<String?> onChanged) {
  int currentYear = DateTime.now().year;
  List<String> years = List.generate(6, (index) => (currentYear + index).toString()); // Generate years from current year to next 5 years

  if (selectedYear != null && !years.contains(selectedYear)) {
    selectedYear = null;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<String>(
      value: selectedYear,
      items: years.map((year) {
        return DropdownMenuItem<String>(
          value: year,
          child: Text(year),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}



Widget _buildMonthSelectField(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2), // Limit to two digits
        FilteringTextInputFormatter.allow(RegExp(r'^(1[0-2]|[1-9])$')), // Restrict to 1-12
      ],
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}


Widget _buildMonthSelectDropdownField(String labelText, IconData icon, String? selectedMonth, ValueChanged<String?> onChanged) {
  List<String> months = List.generate(12, (index) => (index + 1).toString());

  if (selectedMonth != null && !months.contains(selectedMonth)) {
    selectedMonth = null;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<String>(
      value: selectedMonth,
      items: months.map((month) {
        return DropdownMenuItem<String>(
          value: month,
          child: Text(month),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}
Widget _buildNumberField(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Restrict to digits only
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}


Widget _buildForm(BuildContext context, String title, List<Widget> fields) {
  final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(25.0),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: fields,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Center(child: Text('SAVE')),
              onPressed: (){

              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAddForm(BuildContext context, String title, List<Widget> fields) {
  final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(25.0),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: fields,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Center(child: Text('ADD')),
              onPressed: (){

              },
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _buildMonthSelectDropdownFieldTwo(String labelText, IconData icon, String? selectedMonth, ValueChanged<String?> onChanged) {
  List<String> months = List.generate(12, (index) => (index + 1).toString());

  if (selectedMonth != null && !months.contains(selectedMonth)) {
    selectedMonth = null;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<String>(
      value: selectedMonth,
      items: months.map((month) {
        return DropdownMenuItem<String>(
          value: month,
          child: Text(month),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}
Widget _buildNumberFieldTwo(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}

Widget _buildEmailField(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress, // Set keyboard for email input
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}

Widget _buildPhoneFieldTwo(String labelText, IconData icon, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.phone, // Set keyboard for phone input
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Restrict to digits only
      ],
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        labelText: labelText,
        suffixIcon: Icon(icon),
      ),
    ),
  );
}
