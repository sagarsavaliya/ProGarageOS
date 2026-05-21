class StaffMember {
  final String uuid;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String role;
  final String specialty;
  final bool isAvailable;
  final int openJobs;
  final int? completedJobs;
  final double? avgRating;

  const StaffMember({
    required this.uuid,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.role,
    required this.specialty,
    required this.isAvailable,
    required this.openJobs,
    this.completedJobs,
    this.avgRating,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'technician',
      specialty: json['specialty'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      openJobs: (json['open_jobs'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
    );
  }

  String get roleLabel => switch (role) {
        'owner' => 'Owner',
        'service_advisor' => 'Service Advisor',
        'technician' => 'Technician',
        _ => specialty.isNotEmpty ? specialty : role,
      };
}
