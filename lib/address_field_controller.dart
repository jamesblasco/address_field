import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'addres_model.dart';
import 'address_field.dart';

class AddressEditingController extends ValueNotifier<Address> {
  late Map<AddressParams, TextEditingController> controllers;

  AddressEditingController() : super(Address.empty()) {
    controllers = AddressParams.values
        .asMap()
        .map((_, param) => MapEntry(param, TextEditingController()));

    controllers.forEach((_, controller) {
      controller.addListener(notify);
    });
  }

  TextEditingController editingControllerFor(AddressParams param) =>
      controllers[param]!;

  Address get address => value;

  void notify() {
    value = Address(
      state: controllers[AddressParams.state]!.text,
      postalCode: controllers[AddressParams.postalCode]!.text,
      line2: controllers[AddressParams.line2]!.text,
      line1: controllers[AddressParams.line1]!.text,
      country: controllers[AddressParams.country]!.text,
      city: controllers[AddressParams.city]!.text,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) {
      controller.removeListener(notify);
      controller.dispose();
    });
    super.dispose();
  }
}
