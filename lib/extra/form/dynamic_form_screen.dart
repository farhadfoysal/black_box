import 'package:flutter/material.dart';

class DynamicFormScreen extends StatefulWidget {
  @override
  _DynamicFormScreenState createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  final List<Map<String, dynamic>> formFields = [
    {
      "type": "inputText",
      "label": "Your Name",
      "placeholder": "Enter your name",
      "controller": TextEditingController(),
    },
    {
      "type": "textarea",
      "label": "Your Address",
      "placeholder": "Enter your address",
      "controller": TextEditingController(),
    },
    {
      "type": "checkbox",
      "label": "Select Your Hobbies",
      "options": ["Reading", "Traveling", "Gaming", "Cooking"],
      "values": [false, false, false, false],
    },
    {
      "type": "selection",
      "label": "Select Your Country",
      "options": ["USA", "India", "UK", "Canada"],
      "value": null,
    },
    {
      "type": "radio",
      "label": "Select Gender",
      "options": ["Male", "Female", "Other"],
      "value": null,
    },
  ];

  void handleSubmit() {
    // Gather all form data here
    final Map<String, dynamic> formData = {};

    for (var field in formFields) {
      if (field['type'] == 'inputText' || field['type'] == 'textarea') {
        formData[field['label']] = field['controller']?.text;
      } else if (field['type'] == 'checkbox') {
        final List<String> selectedOptions = [];
        for (int i = 0; i < field['options'].length; i++) {
          if (field['values'][i]) {
            selectedOptions.add(field['options'][i]);
          }
        }
        formData[field['label']] = selectedOptions;
      } else if (field['type'] == 'selection' || field['type'] == 'radio') {
        formData[field['label']] = field['value'];
      }
    }

    // Print the gathered form data
    print(formData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Form Submitted Successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dynamic Form"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: formFields.length,
          itemBuilder: (context, index) {
            final field = formFields[index];

            switch (field['type']) {
              case 'inputText':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: field['controller'],
                    decoration: InputDecoration(
                      labelText: field['label'],
                      hintText: field['placeholder'],
                      border: OutlineInputBorder(),
                    ),
                  ),
                );

              case 'textarea':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: field['controller'],
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: field['label'],
                      hintText: field['placeholder'],
                      border: OutlineInputBorder(),
                    ),
                  ),
                );

              case 'checkbox':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field['label'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: List.generate(
                          field['options'].length,
                              (i) => CheckboxListTile(
                            title: Text(field['options'][i]),
                            value: field['values'][i],
                            onChanged: (value) {
                              setState(() {
                                field['values'][i] = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              case 'selection':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: field['label'],
                      border: OutlineInputBorder(),
                    ),
                    items: (field['options'] as List<String>)
                        .map<DropdownMenuItem<String>>(
                            (String option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ))
                        .toList(),
                    value: field['value'] as String?,
                    onChanged: (String? value) {
                      setState(() {
                        field['value'] = value;
                      });
                    },
                  )
                  ,
                );

              case 'radio':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field['label'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: List.generate(
                          field['options'].length,
                              (i) => RadioListTile<String>(
                            title: Text(field['options'][i]),
                            value: field['options'][i],
                            groupValue: field['value'],
                            onChanged: (value) {
                              setState(() {
                                field['value'] = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );

              default:
                return SizedBox.shrink();
            }
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: handleSubmit,
          child: Text("Submit"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      ),
    );
  }
}