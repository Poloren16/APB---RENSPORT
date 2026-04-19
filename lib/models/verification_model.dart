class VerificationRequest {
  final String id;
  final String applicantName;
  final String email;
  final String? username; // Added for account info
  final String? phoneNumber; // Added for Owner Contact
  final String nik;
  final String npwp;
  final String documentUrl;
  final String type; // 'Owner' or 'Venue'
  final String status; // 'Pending', 'Approved', 'Rejected'
  final String? rejectionReason;
  final DateTime submittedAt;
  final String? venueName; // For venue verification
  final String? venueAddress; // For venue verification
  final String? password; // Hidden field to create account later
  final Map<String, dynamic>? venueData; // Full venue details for approval

  VerificationRequest({
    required this.id,
    required this.applicantName,
    required this.email,
    this.username,
    this.phoneNumber,
    required this.nik,
    required this.npwp,
    required this.documentUrl,
    required this.type,
    this.status = 'Pending',
    this.rejectionReason,
    required this.submittedAt,
    this.venueName,
    this.venueAddress,
    this.password,
    this.venueData,
  });

  VerificationRequest copyWith({
    String? status,
    String? rejectionReason,
  }) {
    return VerificationRequest(
      id: id,
      applicantName: applicantName,
      email: email,
      username: username,
      phoneNumber: phoneNumber,
      nik: nik,
      npwp: npwp,
      documentUrl: documentUrl,
      type: type,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt,
      venueName: venueName,
      venueAddress: venueAddress,
      password: password,
      venueData: venueData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'applicantName': applicantName,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'nik': nik,
      'npwp': npwp,
      'documentUrl': documentUrl,
      'type': type,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt.toIso8601String(),
      'venueName': venueName,
      'venueAddress': venueAddress,
      'password': password,
      'venueData': venueData,
    };
  }

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    return VerificationRequest(
      id: map['id'],
      applicantName: map['applicantName'],
      email: map['email'],
      username: map['username'],
      phoneNumber: map['phoneNumber'],
      nik: map['nik'],
      npwp: map['npwp'],
      documentUrl: map['documentUrl'],
      type: map['type'],
      status: map['status'],
      rejectionReason: map['rejectionReason'],
      submittedAt: DateTime.parse(map['submittedAt']),
      venueName: map['venueName'],
      venueAddress: map['venueAddress'],
      password: map['password'],
      venueData: map['venueData'] != null ? Map<String, dynamic>.from(map['venueData']) : null,
    );
  }
}
