class StateData {
  final String state;
  final List<String> districts;

  StateData({required this.state, required this.districts});

  factory StateData.fromJson(Map<String, dynamic> json) {
    return StateData(
      state: json['state'],
      districts: List<String>.from(json['districts']),
    );
  }
}
