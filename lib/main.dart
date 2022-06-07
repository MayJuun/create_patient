import 'package:fhir/r4.dart';
import 'package:fhir_at_rest/r4.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Create Patient',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CreatePatient(),
    );
  }
}

class CreatePatient extends StatelessWidget {
  const CreatePatient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Text editing controllers for names
    final lastName = TextEditingController();
    final firstName = TextEditingController();
    Id? patientId;

    /// Container for entering a name
    Container _nameContainer(TextEditingController name, String text) =>
        Container(
          width: Get.width / 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: name,
            decoration: InputDecoration(hintText: text),
          ),
        );

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //* Hapi FHIR calls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              /// Call the name containers, one for first and last name
              _nameContainer(lastName, 'Last name'),
              _nameContainer(firstName, 'First name'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              /// Buttons created to do something
              /// Creates the patient on a HAPI server
              SmallActionButton(
                  title: 'Hapi: Create',
                  onPressed: () async {
                    patientId = await _hapiCreate(
                      firstName.text,
                      lastName.text,
                    );
                  }),

              /// Launches that patient on a HAPI server
              SmallActionButton(
                title: 'Hapi: Search',
                onPressed: () => _hapiSearch(
                  firstName.text,
                  lastName.text,
                  patientId,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<Id?> _hapiCreate(String lastName, String firstName) async {
    var newPatient = Patient(
      name: [
        HumanName(
          given: [firstName],
          family: lastName,
        ),
      ],
    );
    var newRequest = FhirRequest.create(
      base: Uri.parse('https://hapi.fhir.org/baseR4'),
      resource: newPatient,
    );
    var response = await newRequest
        .request(headers: {'Content-Type': 'application/fhir+json'});
    if (response.resourceType == R4ResourceType.Patient) {
      Get.rawSnackbar(
          title: 'Success',
          message: 'Patient ${(response as Patient).name?[0].given?[0]}'
              ' ${response.name?[0].family} created');
      print(response.toJson());
    } else {
      Get.snackbar('Failure', '${response.toJson()}',
          snackPosition: SnackPosition.BOTTOM);
      print(response.toJson());
    }
    return response.id;
  }

  Future _hapiSearch(
    String lastName,
    String firstName,
    Id? patientId,
  ) async {
    if (patientId != null) {
      await launchUrlString('http://hapi.fhir.org/baseR4/'
          'Patient'
          '?_id=$patientId'
          '&_pretty=true');
    } else {
      await launchUrlString('http://hapi.fhir.org/baseR4/'
          'Patient'
          '?given=$firstName'
          '&family=$lastName'
          '&_pretty=true');
    }
  }
}

class SmallActionButton extends StatelessWidget {
  const SmallActionButton(
      {Key? key, required this.title, required this.onPressed})
      : super(key: key);

  final String title;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ButtonTheme.fromButtonThemeData(
      data: Get.theme.buttonTheme.copyWith(minWidth: Get.width / 3),
      child: ElevatedButton(onPressed: onPressed, child: Text(title)),
    );
  }
}
