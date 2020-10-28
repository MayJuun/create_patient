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
    return GetBuilder<CreatePatientController>(
      init: CreatePatientController(),
      builder: (data) => data.isBusy
          ? Center(child: CircularProgressIndicator())
          : Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //* Hapi FHIR calls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _nameContainer(data.lastName, 'Last name'),
                      _nameContainer(data.firstName, 'First name'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      SmallActionButton(
                          title: 'Hapi: Create',
                          onPressed: () => data.hapiCreate()),
                      SmallActionButton(
                          title: 'Hapi: Search',
                          onPressed: () => data.hapiSearch()),
                    ],
                  )
                ],
              ),
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
}

class CreatePatientController extends GetxController {
  bool isBusy = false;

  final _lastName = TextEditingController();
  final _firstName = TextEditingController();

  TextEditingController get lastName => _lastName;
  TextEditingController get firstName => _firstName;

  Future hapiCreate() async {
    isBusy = true;
    update();
    var newPatient = Patient(
      resourceType: 'Patient',
      name: [
        HumanName(
          given: [_firstName.text],
          family: _lastName.text,
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
    isBusy = false;
    update();
  }

  Future hapiSearch() async {
    isBusy = true;
    update();
    await launch('http://hapi.fhir.org/baseR4/'
        'Patient?given=${_firstName.text}&family=${_lastName.text}&_pretty=true');
    isBusy = false;
    update();
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