int? _int(dynamic v) => v == null ? null : (v as num).toInt();

class AppUser {
  final String id, email, fullName, accountType;
  final String? phone, companyId;
  AppUser.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        email = j['email'],
        fullName = j['fullName'],
        accountType = j['accountType'],
        phone = j['phone'],
        companyId = j['companyId'];
}

class Course {
  final String id, slug, title, category;
  final String? summary, description, audience, requirements;
  final int? durationDays, priceKobo;
  Course.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        slug = j['slug'],
        title = j['title'],
        category = j['category'] ?? '',
        summary = j['summary'],
        description = j['description'],
        audience = j['audience'],
        requirements = j['requirements'],
        durationDays = _int(j['durationDays']),
        priceKobo = _int(j['priceKobo']);
}

class Session {
  final String id, startDate, endDate, status;
  final String? examDate, location, title, category, courseId;
  final int? capacity, seatsLeft, priceKobo;
  Session.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        startDate = j['startDate'],
        endDate = j['endDate'],
        status = j['status'],
        examDate = j['examDate'],
        location = j['location'],
        title = j['title'],
        category = j['category'],
        courseId = j['courseId'],
        capacity = _int(j['capacity']),
        seatsLeft = _int(j['seatsLeft']),
        priceKobo = _int(j['priceKobo']);
}

class Registration {
  final String id, status, paymentStatus, attendeeName, attendeeEmail, courseTitle, startDate, endDate;
  final String? location, examDate;
  final int? amountKobo;
  Registration.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        status = j['status'],
        paymentStatus = j['paymentStatus'],
        attendeeName = j['attendeeName'],
        attendeeEmail = j['attendeeEmail'],
        courseTitle = j['courseTitle'],
        startDate = j['startDate'],
        endDate = j['endDate'],
        location = j['location'],
        examDate = j['examDate'],
        amountKobo = _int(j['amountKobo']);
}

class Certificate {
  final String certificateNumber, holderName, courseTitle, issuedOn, state;
  final String? awardingBody, expiresOn;
  Certificate.fromJson(Map<String, dynamic> j)
      : certificateNumber = j['certificateNumber'],
        holderName = j['holderName'],
        courseTitle = j['courseTitle'],
        issuedOn = j['issuedOn'],
        state = j['state'],
        awardingBody = j['awardingBody'],
        expiresOn = j['expiresOn'];
}

class StaffMember {
  final String id, fullName, email;
  final String? phone, jobTitle;
  StaffMember.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        fullName = j['fullName'],
        email = j['email'],
        phone = j['phone'],
        jobTitle = j['jobTitle'];
}
