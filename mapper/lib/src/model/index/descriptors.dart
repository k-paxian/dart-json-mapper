/// Describes resolved property name and value
class PropertyDescriptor {
  String name;
  dynamic value;
  bool raw; // value should be deserialized before use
  PropertyDescriptor(this.name, this.value, this.raw);
}

/// Describes an Object being processed through recursion to track cycling
/// use case. Used to prevent dead loops during recursive process
class ProcessedObjectDescriptor {
  dynamic object;
  Map<int, int> usages = {}; // level : usagesCounter

  ProcessedObjectDescriptor(this.object);

  int get levelsCount {
    return usages.keys.length;
  }

  void logUsage(int level) {
    if (usages.containsKey(level)) {
      usages.update(level, (value) => ++value);
    } else {
      usages[level] = 1;
    }
  }

  @override
  String toString() {
    return '$object / $usages';
  }
}
