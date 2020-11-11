import 'package:fhir/r4.dart';
import 'package:fhir_at_rest/requests/request_types.dart';
import 'package:fhir_at_rest/resource_types/resource_types.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Create Patient',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CreatePatient(),
    );
  }
}

class CreatePatient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _lastName = TextEditingController();
    final _firstName = TextEditingController();

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //* Hapi FHIR calls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _nameContainer(_lastName, 'Last name'),
              _nameContainer(_firstName, 'First name'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SmallActionButton(
                  title: 'Hapi: Create',
                  onPressed: () =>
                      _hapiCreate(_firstName.text, _lastName.text)),
              SmallActionButton(
                  title: 'Hapi: Search',
                  onPressed: () =>
                      _hapiSearch(_firstName.text, _lastName.text)),
            ],
          )
        ],
      ),
    );
  }

  Container _nameContainer(TextEditingController name, String text) =>
      Container(
        width: Get.width / 3,
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: name,
          decoration: InputDecoration(hintText: text),
        ),
      );

  Future _hapiCreate(String lastName, String firstName) async {
    var newPatient = Patient(
      resourceType: 'Patient',
      name: [
        HumanName(
          given: [firstName],
          family: lastName,
        ),
      ],
    );
    var newRequest = CreateRequest.r4(
      base: Uri.parse('https://hapi.fhir.org/baseR4'),
      type: R4Types.patient,
    );
    var response = await newRequest.request(resource: newPatient);
    response.fold((l) {
      Get.snackbar('Failure', '${l.errorMessage()}',
          snackPosition: SnackPosition.BOTTOM);
      print(l.errorMessage());
    },
        (r) => Get.rawSnackbar(
            title: 'Success',
            message: 'Patient ${(r as Patient).name[0].given[0]}'
                ' ${(r as Patient).name[0].family} created'));
  }

  Future _hapiSearch(String lastName, String firstName) async {
    await launch('http://hapi.fhir.org/baseR4/'
        'Patient?given=$firstName&family=$lastName&_pretty=true');
  }
}

class SmallActionButton extends StatelessWidget {
  final String title;
  final void Function() onPressed;

  const SmallActionButton({Key key, @required this.title, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ButtonTheme.fromButtonThemeData(
      data: Get.theme.buttonTheme.copyWith(minWidth: Get.width / 3),
      child: RaisedButton(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Text(title),
          onPressed: onPressed),
    );
  }
}
