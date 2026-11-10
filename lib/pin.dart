enum PinStatus { incomplete, incorrect, valid }

PinStatus checkPin(List<String> fields) {
  if (fields.length != 4 || fields.any((value) => !RegExp(r'^\d$').hasMatch(value))) {
    return PinStatus.incomplete;
  }
  return fields.join() == '3245' ? PinStatus.valid : PinStatus.incorrect;
}
