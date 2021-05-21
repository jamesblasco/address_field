import 'package:address_field/addres_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'address_field_controller.dart';
import 'mapbox_search.dart/mapbox.dart';

enum AddressParams { line1, line2, city, state, postalCode, country }

class AddressField extends StatefulWidget {
  final FocusNode? focusNode;
  final AddressEditingController? controller;
  final double spacing;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool resizeAnimation;
  final AddressSearch? autocomplete;

  AddressField({
    Key? key,
    FocusNode? focusNode,
    this.controller,
    this.spacing = 8,
    this.decoration,
    this.style,
    this.resizeAnimation = true,
    this.autocomplete,
  })  : focusNode = focusNode ?? FocusNode(),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> with TickerProviderStateMixin {
  late Map<AddressParams, FocusNode> focusNodes;
  late FocusNode _focusNode = FocusNode();
  late AddressEditingController controller;

  FocusNode get effectiveFocusNode {
    return widget.focusNode ?? _focusNode;
  }

  @override
  void initState() {
    focusNodes = {
      for (final param in AddressParams.values) param: FocusNode(),
    };
    controller = widget.controller ?? AddressEditingController();

    focusNodes.forEach((_, node) => node.addListener(updateFocus));
    super.initState();
  }

  void updateFocus() {
    suggestions.clear();
    setState(() {});
  }

  List<Address> suggestions = [];
  Future<void> search() async {
    final autocomplete = await widget.autocomplete
            ?.search(controller.editingControllerFor(AddressParams.line1).text) ??
        [];
    suggestions.clear();
    suggestions.addAll(autocomplete);
    setState(() {});
  }

  Widget _form() {
    final decoration = widget.decoration ?? InputDecoration();
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RawAutocomplete<Address>(
            textEditingController: controller.editingControllerFor(AddressParams.line1),
            focusNode: focusNodes[AddressParams.line1],
            displayStringForOption: (option) => option.line1,
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextFormField(
                scrollPadding: EdgeInsets.fromLTRB(20, 20, 20, 200),
                focusNode: focusNode,
                decoration: decoration.copyWith(hintText: 'Address line 1'),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  if (value.characters.length > 3) {
                    search();
                  }
                },
                autofillHints: [AutofillHints.streetAddressLine1],
                controller: controller.editingControllerFor(AddressParams.line1),
                onFieldSubmitted: (String value) {
                  onFieldSubmitted();
                },
              );
            },
            optionsBuilder: (value) => suggestions,
            optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Address> onSelected,
                Iterable<Address> options) {
              return _AutocompleteOptions<Address>(
                displayStringForOption: (option) => option.text,
                onSelected: onSelected,
                options: options,
              );
            },
            onSelected: (option) {
              controller.editingControllerFor(AddressParams.city).text = option.line1;
              controller.editingControllerFor(AddressParams.city).text = option.city;
              controller.editingControllerFor(AddressParams.state).text = option.state;
              controller.editingControllerFor(AddressParams.postalCode).text = option.postalCode;
              controller.editingControllerFor(AddressParams.country).text = option.country;
              focusNodes[AddressParams.line1]!.nextFocus();
            },
          ),
          SizedBox(height: widget.spacing),
          TextField(
            focusNode: focusNodes[AddressParams.line2],
            decoration: decoration.copyWith(hintText: 'Address line 2'),
            textInputAction: TextInputAction.next,
            autofillHints: [AutofillHints.streetAddressLine2],
            controller: controller.editingControllerFor(AddressParams.line2),
          ),
          SizedBox(height: widget.spacing),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  focusNode: focusNodes[AddressParams.city],
                  decoration: decoration.copyWith(hintText: 'City'),
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.addressCity],
                  controller: controller.editingControllerFor(AddressParams.city),
                ),
              ),
              SizedBox(width: widget.spacing),
              Expanded(
                child: TextField(
                  focusNode: focusNodes[AddressParams.state],
                  decoration: decoration.copyWith(hintText: 'State'),
                  textInputAction: TextInputAction.next,
                  autofillHints: [AutofillHints.addressState],
                  controller: controller.editingControllerFor(AddressParams.state),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  focusNode: focusNodes[AddressParams.postalCode],
                  decoration: decoration.copyWith(hintText: 'Postal Code'),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  autofillHints: [AutofillHints.postalCode],
                  controller: controller.editingControllerFor(AddressParams.postalCode),
                ),
              ),
              SizedBox(width: widget.spacing),
              Expanded(
                child: TextField(
                  focusNode: focusNodes[AddressParams.country],
                  decoration: decoration.copyWith(hintText: 'Country'),
                  textInputAction: TextInputAction.done,
                  autofillHints: [AutofillHints.countryName],
                  controller: controller.editingControllerFor(AddressParams.country),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    focusNodes.forEach((_, node) => node.removeListener(updateFocus));
    super.dispose();
  }

  bool _isHovering = false;

  void _handleHover(bool hovering) {
    if (hovering != _isHovering) {
      setState(() {
        _isHovering = hovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MouseCursor effectiveMouseCursor = MaterialStateProperty.resolveAs<MouseCursor>(
      //  widget.mouseCursor ??
      MaterialStateMouseCursor.textable,
      <MaterialState>{
        //    if (!_isEnabled) MaterialState.disabled,
        if (_isHovering) MaterialState.hovered,
        if (effectiveFocusNode.hasFocus) MaterialState.focused,
        // if (_hasError) MaterialState.error,
      },
    );
    final theme = Theme.of(context);
    final decoration = widget.decoration ?? InputDecoration();
    final style = theme.textTheme.subtitle1!.merge(widget.style);
    final isEmpty = controller.address.line1.isEmpty;
    final isFocused = effectiveFocusNode.hasFocus || focusNodes.values.any((node) => node.hasFocus);
    return Focus(
      focusNode: effectiveFocusNode,
      onFocusChange: (bool focus) {
        if (focus && !focusNodes[AddressParams.line1]!.hasFocus) {
          focusNodes[AddressParams.line1]!.requestFocus();
        }
        setState(() {});
      },
      child: isFocused
          ? _form()
          : MouseRegion(
              cursor: effectiveMouseCursor,
              onEnter: (PointerEnterEvent event) => _handleHover(true),
              onExit: (PointerExitEvent event) => _handleHover(false),
              child: AnimatedSize(
                alignment: Alignment.topCenter,
                duration: Duration(milliseconds: 400),
                vsync: this,
                child: GestureDetector(
                  onTap: () => effectiveFocusNode.requestFocus(),
                  child: InputDecorator(
                    baseStyle: style,
                    isHovering: _isHovering,
                    isEmpty: isEmpty,
                    decoration: decoration,
                    child: !isEmpty
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  controller.address.text,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(controller.address.city),
                              SizedBox(width: 12),
                              Text(controller.address.country),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
            ),
    );
  }
}

// The default Material-style Autocomplete options.
class _AutocompleteOptions<T extends Object> extends StatelessWidget {
  const _AutocompleteOptions({
    Key? key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.options,
  }) : super(key: key);

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;

  final Iterable<T> options;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.only(top: 0, right: 48),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(maxHeight: 200.0),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final T option = options.elementAt(index);
                return InkWell(
                  onTap: () {
                    onSelected(option);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(displayStringForOption(option)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
