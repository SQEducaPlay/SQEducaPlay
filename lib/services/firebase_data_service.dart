import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../database/app_database.dart';
import '../models/user_model.dart' as app_model;
import 'firebase_service.dart';
import 'password_service.dart';

abstract final class FirebaseDataService {
  static FirebaseFirestore get _db => FirebaseService.instance.firestore;
  static firebase_auth.FirebaseAuth get _auth => FirebaseService.instance.auth;

  static String createClientSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static String _randomCode(String prefix) {
    final random = Random.secure();
    final hex = List<int>.generate(20, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return '$prefix$hex';
  }

  static String _uid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sua sessão Firebase expirou.');
    return uid;
  }

  static Map<String, dynamic> _map(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) throw StateError('Documento Firebase não encontrado.');
    final mapped = {'id': document.id, ...data};
    const aliases = {
      'uid': 'user_id',
      'fullName': 'full_name',
      'schoolId': 'school_id',
      'studentId': 'student_id',
      'classroomId': 'classroom_id',
      'userId': 'user_id',
      'studentCode': 'student_code',
      'primarySchoolId': 'primary_school_id',
    };
    for (final entry in aliases.entries) {
      if (data.containsKey(entry.key)) mapped[entry.value] = data[entry.key];
    }
    return mapped;
  }

  static Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (role != 'student' && role != 'guardian') {
      throw ArgumentError.value(role, 'role', 'Perfil de cadastro inválido.');
    }
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final authUser = credential.user;
    if (authUser == null) {
      throw StateError('Firebase não retornou a conta criada.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final profile = _db.collection('users').doc(authUser.uid);
    final emailIndex = _db.collection('emailIndex').doc(normalizedEmail);
    final batch = _db.batch();
    batch.set(profile, {
      'uid': authUser.uid,
      'email': normalizedEmail,
      'fullName': fullName.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(emailIndex, {'uid': authUser.uid, 'email': normalizedEmail});
    try {
      await batch.commit();
    } catch (error) {
      try {
        await authUser.delete();
      } catch (cleanupError) {
        throw StateError(
          'Não foi possível salvar o perfil Firebase ($error) nem remover a conta incompleta ($cleanupError).',
        );
      }
      rethrow;
    }
    return credential;
  }

  static Future<Map<String, dynamic>> fetchCurrentProfile() async {
    final uid = _uid();
    final profile = await _db.collection('users').doc(uid).get();
    return _map(profile);
  }

  static Future<Map<String, dynamic>> exportCurrentAccountData() async {
    final uid = _uid();
    final profile = await _db.collection('users').doc(uid).get();
    final memberships = await _db
        .collection('memberships')
        .where('userId', isEqualTo: uid)
        .get();
    final schools = <Map<String, dynamic>>[];
    for (final membership in memberships.docs) {
      final schoolId = membership.data()['schoolId'] as String?;
      if (schoolId == null) continue;
      final school = await _db.collection('schools').doc(schoolId).get();
      if (school.exists) schools.add(_map(school));
    }
    final teacherInvites = await _db
        .collection('teacherInvites')
        .where('createdBy', isEqualTo: uid)
        .get();
    final receivedInvites = await _db
        .collection('teacherInvites')
        .where('email', isEqualTo: _auth.currentUser?.email?.toLowerCase())
        .get();
    final allInvites = {
      for (final invite in teacherInvites.docs) invite.id: invite,
      for (final invite in receivedInvites.docs) invite.id: invite,
    }.values;
    final guardianStudents = await _db
        .collection('students')
        .where('guardianId', isEqualTo: uid)
        .get();
    final ownedStudents = await _db
        .collection('students')
        .where('ownerUid', isEqualTo: uid)
        .get();
    final studentDocuments = {
      for (final student in guardianStudents.docs) student.id: student,
      for (final student in ownedStudents.docs) student.id: student,
    }.values;
    final students = <Map<String, dynamic>>[];
    final enrollments = <Map<String, dynamic>>[];
    final sessions = <Map<String, dynamic>>[];
    final attempts = <Map<String, dynamic>>[];
    final progress = <Map<String, dynamic>>[];
    final consents = <Map<String, dynamic>>[];
    for (final studentDocument in studentDocuments) {
      final studentId = studentDocument.id;
      students.add(_map(studentDocument));
      final studentPath = _db.collection('students').doc(studentId);
      final studentEnrollments = await _db
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .get();
      enrollments.addAll(studentEnrollments.docs.map(_map));
      final studentSessions = await studentPath
          .collection('quizSessions')
          .get();
      for (final session in studentSessions.docs) {
        sessions.add({'studentId': studentId, ..._map(session)});
        final sessionAttempts = await session.reference
            .collection('attempts')
            .get();
        attempts.addAll(
          sessionAttempts.docs.map(
            (attempt) => {
              'studentId': studentId,
              'sessionId': session.id,
              ..._map(attempt),
            },
          ),
        );
      }
      final studentProgress = await studentPath.collection('progress').get();
      progress.addAll(
        studentProgress.docs.map(
          (row) => {'studentId': studentId, ..._map(row)},
        ),
      );
      final studentConsents = await studentPath
          .collection('consents')
          .where('guardianId', isEqualTo: uid)
          .get();
      consents.addAll(
        studentConsents.docs.map(
          (row) => {'studentId': studentId, ..._map(row)},
        ),
      );
    }
    final links = await _db
        .collection('studentLinks')
        .where('guardianId', isEqualTo: uid)
        .get();

    return _jsonSafe({
          'exportedAt': DateTime.now().toUtc().toIso8601String(),
          'source': 'firebase',
          'auth': {'uid': uid, 'email': _auth.currentUser?.email},
          'profile': profile.exists ? _map(profile) : null,
          'memberships': memberships.docs.map(_map).toList(),
          'schools': schools,
          'teacherInvites': allInvites.map(_map).toList(),
          'studentProfiles': students,
          'enrollments': enrollments,
          'quizSessions': sessions,
          'questionAttempts': attempts,
          'progress': progress,
          'consentRecords': consents,
          'studentLinks': links.docs.map(_map).toList(),
        })
        as Map<String, dynamic>;
  }

  static Future<List<String>> listManagedStudentIds() async {
    final uid = _uid();
    final guardianStudents = await _db
        .collection('students')
        .where('guardianId', isEqualTo: uid)
        .get();
    final ownedStudents = await _db
        .collection('students')
        .where('ownerUid', isEqualTo: uid)
        .get();
    return {
      ...guardianStudents.docs.map((student) => student.id),
      ...ownedStudents.docs.map((student) => student.id),
    }.toList();
  }

  static Future<void> deleteCurrentAccount({required String password}) async {
    final authUser = _auth.currentUser;
    if (authUser == null || authUser.email == null) {
      throw StateError('A sessão Firebase não está ativa.');
    }
    final profileRef = _db.collection('users').doc(authUser.uid);
    final profile = await profileRef.get();
    if (profile.data()?['role'] == 'admin') {
      throw StateError(
        'A conta de administrador principal precisa ser removida por um administrador do projeto.',
      );
    }
    await authUser.reauthenticateWithCredential(
      firebase_auth.EmailAuthProvider.credential(
        email: authUser.email!,
        password: password,
      ),
    );

    final uid = authUser.uid;
    final studentIds = await listManagedStudentIds();
    final references = <DocumentReference<Map<String, dynamic>>>[];
    final referencePaths = <String>{};
    void addReference(DocumentReference<Map<String, dynamic>> reference) {
      if (referencePaths.add(reference.path)) references.add(reference);
    }

    for (final studentId in studentIds) {
      final studentRef = _db.collection('students').doc(studentId);
      final student = await studentRef.get();
      if (!student.exists) continue;
      final data = student.data()!;
      final code = data['studentCode'] as String?;
      final username = data['username'] as String?;
      if (code != null) addReference(_db.collection('studentCodes').doc(code));
      if (username != null) {
        addReference(_db.collection('studentUsernames').doc(username));
      }

      final sessions = await studentRef.collection('quizSessions').get();
      for (final session in sessions.docs) {
        final attempts = await session.reference.collection('attempts').get();
        for (final attempt in attempts.docs) {
          addReference(attempt.reference);
        }
        addReference(session.reference);
      }
      for (final row in (await studentRef.collection('progress').get()).docs) {
        addReference(row.reference);
      }
      for (final row
          in (await studentRef
                  .collection('consents')
                  .where('guardianId', isEqualTo: uid)
                  .get())
              .docs) {
        addReference(row.reference);
      }
      for (final row
          in (await _db
                  .collection('enrollments')
                  .where('studentId', isEqualTo: studentId)
                  .get())
              .docs) {
        addReference(row.reference);
      }
      addReference(studentRef);
    }

    for (final row
        in (await _db
                .collection('studentLinks')
                .where('guardianId', isEqualTo: uid)
                .get())
            .docs) {
      addReference(row.reference);
    }
    for (final row
        in (await _db
                .collection('memberships')
                .where('userId', isEqualTo: uid)
                .get())
            .docs) {
      addReference(row.reference);
    }
    for (final row
        in (await _db
                .collection('teacherInvites')
                .where('createdBy', isEqualTo: uid)
                .get())
            .docs) {
      addReference(row.reference);
    }
    for (final row
        in (await _db
                .collection('teacherInvites')
                .where('email', isEqualTo: authUser.email!.toLowerCase())
                .get())
            .docs) {
      addReference(row.reference);
    }
    final email = authUser.email!.trim().toLowerCase();
    final emailIndex = await _db.collection('emailIndex').doc(email).get();
    if (emailIndex.exists) addReference(emailIndex.reference);
    if (profile.exists) addReference(profileRef);

    for (var start = 0; start < references.length; start += 400) {
      final batch = _db.batch();
      for (final reference in references.skip(start).take(400)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
    await authUser.delete();
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is DocumentReference) return value.path;
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), _jsonSafe(nestedValue)),
      );
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value;
  }

  static Future<String> createSelfStudentProfile({
    required String fullName,
    required String grade,
    String? schoolId,
  }) async {
    final uid = _uid();
    final profile = await _db.collection('users').doc(uid).get();
    if (profile.data()?['role'] != 'student') {
      throw StateError('Esta conta não está registrada como aluno.');
    }

    final code = _randomCode('ALU-');
    final username = 'aluno-${code.substring(4, 16).toLowerCase()}';
    final student = _db.collection('students').doc(uid);
    final studentCode = _db.collection('studentCodes').doc(code);
    final studentUsername = _db.collection('studentUsernames').doc(username);
    final batch = _db.batch();
    batch.set(student, {
      'ownerUid': uid,
      'guardianId': null,
      'username': username,
      'fullName': fullName.trim(),
      'nickname': null,
      'grade': grade.trim(),
      'schoolId': schoolId,
      'status': 'active',
      'studentCode': code,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(studentCode, {
      'studentId': uid,
      'ownerUid': uid,
      'fullName': fullName.trim(),
      'grade': grade.trim(),
      'schoolId': schoolId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(studentUsername, {
      'studentId': uid,
      'ownerUid': uid,
      'guardianId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return code;
  }

  static Future<Map<String, dynamic>?> fetchOwnStudentProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final student = await _db.collection('students').doc(uid).get();
    return student.exists ? _map(student) : null;
  }

  static Future<String> createChildProfile({
    required String username,
    required String fullName,
    String? nickname,
    required String grade,
    required String consentVersion,
    String? schoolId,
  }) async {
    final guardianId = _uid();
    final guardian = await _db.collection('users').doc(guardianId).get();
    if (!{'guardian', 'admin'}.contains(guardian.data()?['role'])) {
      throw StateError('Somente uma conta de responsável pode criar perfis.');
    }

    final schoolStatus = schoolId == null ? 'active' : 'pending';
    final normalizedUsername = username.trim().toLowerCase();
    final student = _db.collection('students').doc();
    final consent = student.collection('consents').doc();
    final studentUsername = _db
        .collection('studentUsernames')
        .doc(normalizedUsername);
    final batch = _db.batch();
    batch.set(student, {
      'ownerUid': null,
      'guardianId': guardianId,
      'username': normalizedUsername,
      'fullName': fullName.trim(),
      'nickname': nickname?.trim().isEmpty == true ? null : nickname?.trim(),
      'grade': grade.trim(),
      'schoolId': schoolId,
      'status': schoolStatus,
      'studentCode': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(consent, {
      'guardianId': guardianId,
      'version': consentVersion,
      'consentedAt': FieldValue.serverTimestamp(),
    });
    batch.set(studentUsername, {
      'studentId': student.id,
      'ownerUid': null,
      'guardianId': guardianId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return student.id;
  }

  static Future<List<Map<String, dynamic>>> listChildren() async {
    final rows = await _db
        .collection('students')
        .where('guardianId', isEqualTo: _uid())
        .get();
    final children = rows.docs.map(_map).toList();
    children.sort(
      (a, b) =>
          (a['createdAt'] as Timestamp?)?.compareTo(
            b['createdAt'] as Timestamp? ?? Timestamp(0, 0),
          ) ??
          0,
    );
    return children;
  }

  static Future<List<Map<String, dynamic>>> listActiveSchools({
    bool includeInactive = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    final profile = uid == null
        ? null
        : (await _db.collection('users').doc(uid).get()).data();
    final canSeeInactive = includeInactive && profile?['role'] == 'admin';
    final schoolQuery = _db.collection('schools');
    final rows = canSeeInactive
        ? await schoolQuery.get()
        : await schoolQuery.where('active', isEqualTo: true).get();
    final schools = rows.docs
        .map(_map)
        .where((school) => canSeeInactive || school['active'] == true)
        .toList();
    schools.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return schools;
  }

  static Future<List<Map<String, dynamic>>> listLinkedStudents() async {
    final rows = await _db
        .collection('studentLinks')
        .where('guardianId', isEqualTo: _uid())
        .get();
    final students = <Map<String, dynamic>>[];
    for (final link in rows.docs) {
      final studentId = link.data()['studentId'] as String?;
      if (studentId == null) continue;
      final student = await _db.collection('students').doc(studentId).get();
      if (student.exists) students.add(_map(student));
    }
    return students;
  }

  static Future<Map<String, dynamic>> linkStudentByCode(String code) async {
    final uid = _uid();
    final normalizedCode = code.trim().toUpperCase();
    final codeRow = await _db
        .collection('studentCodes')
        .doc(normalizedCode)
        .get();
    if (!codeRow.exists) throw StateError('Código de aluno não encontrado.');
    final codeData = codeRow.data()!;
    final studentId = codeData['studentId'] as String;
    if (codeData['ownerUid'] == null) {
      throw StateError(
        'Este código não corresponde a um aluno com conta própria.',
      );
    }
    final linkId = '${uid}_$studentId';
    await _db.collection('studentLinks').doc(linkId).set({
      'guardianId': uid,
      'studentId': studentId,
      'code': normalizedCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final student = await _db.collection('students').doc(studentId).get();
    return _map(student);
  }

  static Future<app_model.User> activateStudent(
    Map<String, dynamic> student,
  ) async {
    final studentId = student['id'] as String;
    final localUser = await AppDatabase.instance.getOrCreateRemoteStudent(
      remoteStudentId: studentId,
      username: student['username'] as String,
      fullName: student['fullName'] as String,
      nickname: student['nickname'] as String?,
      grade: student['grade'] as String,
      isApproved: student['status'] == 'active',
    );
    await syncPendingSessions(studentId);
    await _downloadQuizHistory(studentId);
    return localUser;
  }

  static Future<int> migrateLocalStudentHistory({
    required app_model.User sourceUser,
    required String sourcePassword,
    required app_model.User remoteStudent,
    required String consentVersion,
  }) async {
    if (sourceUser.id == null ||
        sourceUser.role != 'student' ||
        sourceUser.remoteStudentId != null ||
        !PasswordService.verifyPassword(sourcePassword, sourceUser.password)) {
      throw ArgumentError('A conta local ou a senha não foi validada.');
    }
    final remoteStudentId = remoteStudent.remoteStudentId;
    final targetUserId = remoteStudent.id;
    if (remoteStudentId == null || targetUserId == null) {
      throw StateError('O perfil Firebase ainda não está preparado.');
    }

    final localSessions = await AppDatabase.instance.buscarPartidasUsuario(
      sourceUser.id!,
    );
    final importableCount = localSessions
        .where((session) => session['remote_student_id'] == null)
        .length;
    if (importableCount == 0) return 0;

    await _db
        .collection('students')
        .doc(remoteStudentId)
        .collection('consents')
        .add({
          'guardianId': _uid(),
          'version': consentVersion,
          'consentedAt': FieldValue.serverTimestamp(),
        });
    final clientSessionIds = List.generate(
      importableCount,
      (_) => createClientSessionId(),
    );
    final attached = await AppDatabase.instance
        .attachLocalStudentHistoryToRemote(
          sourceUserId: sourceUser.id!,
          targetUserId: targetUserId,
          remoteStudentId: remoteStudentId,
          clientSessionIds: clientSessionIds,
        );
    await syncPendingSessions(remoteStudentId);
    return attached;
  }

  static Future<void> syncPendingSessions(String studentId) async {
    final pending = await AppDatabase.instance.getPendingRemoteQuizSessions(
      studentId,
    );
    for (final session in pending) {
      final clientSessionId = session['client_session_id'] as String?;
      if (clientSessionId == null) {
        throw StateError(
          'Partida pendente sem identificador de sincronização.',
        );
      }
      final sessionRef = _db
          .collection('students')
          .doc(studentId)
          .collection('quizSessions')
          .doc(clientSessionId);
      final batch = _db.batch();
      batch.set(sessionRef, {
        'studentId': studentId,
        'clientSessionId': clientSessionId,
        'subject': session['materia'],
        'grade': session['ano'],
        'topic': session['topico'],
        'score': session['pontuacao'],
        'stars': session['estrelas'],
        'correctAnswers': session['acertos'],
        'totalQuestions': session['total_perguntas'],
        'durationSeconds': session['tempo_segundos'],
        'completedAt': Timestamp.fromDate(
          DateTime.tryParse(session['data_partida'] as String? ?? '') ??
              DateTime.now(),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final attempts = session['attempts'];
      if (attempts is List) {
        for (var index = 0; index < attempts.length; index++) {
          final attempt = Map<String, dynamic>.from(attempts[index] as Map);
          batch.set(sessionRef.collection('attempts').doc('$index'), {
            'question': attempt['pergunta'] ?? '',
            'selectedAnswer': attempt['resposta_selecionada'] ?? '',
            'correctAnswer': attempt['resposta_correta'] ?? '',
            'isCorrect': attempt['acertou'] == true,
            'questionOrder': attempt['ordem_pergunta'] ?? index,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      await AppDatabase.instance.markRemoteQuizSessionSynced(
        clientSessionId,
        remoteSessionId: clientSessionId,
      );
    }
  }

  static Future<void> _downloadQuizHistory(String studentId) async {
    final rows = await _db
        .collection('students')
        .doc(studentId)
        .collection('quizSessions')
        .orderBy('completedAt')
        .get();
    for (final row in rows.docs) {
      final data = row.data();
      final attempts = await row.reference
          .collection('attempts')
          .orderBy('questionOrder')
          .get();
      await AppDatabase.instance.importRemoteQuizSession(
        session: {
          'id': row.id,
          'student_id': studentId,
          'client_session_id': data['clientSessionId'],
          'subject': data['subject'],
          'grade': data['grade'],
          'topic': data['topic'],
          'score': data['score'],
          'stars': data['stars'],
          'correct_answers': data['correctAnswers'],
          'total_questions': data['totalQuestions'],
          'duration_seconds': data['durationSeconds'],
          'completed_at': (data['completedAt'] as Timestamp?)
              ?.toDate()
              .toIso8601String(),
        },
        attempts: attempts.docs
            .map(
              (attempt) => {
                'question': attempt.data()['question'],
                'selected_answer': attempt.data()['selectedAnswer'],
                'correct_answer': attempt.data()['correctAnswer'],
                'is_correct': attempt.data()['isCorrect'],
                'question_order': attempt.data()['questionOrder'],
                'created_at': (attempt.data()['createdAt'] as Timestamp?)
                    ?.toDate()
                    .toIso8601String(),
              },
            )
            .toList(),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> listMemberships(String uid) async {
    final rows = await _db
        .collection('memberships')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .get();
    return rows.docs.map(_map).toList();
  }

  static Future<List<Map<String, dynamic>>> listAuthorizedSchools({
    required bool isPlatformAdmin,
    required List<Map<String, dynamic>> memberships,
  }) async {
    if (isPlatformAdmin) return listActiveSchools(includeInactive: true);
    final ids = memberships
        .map((membership) => membership['schoolId'] as String)
        .toSet();
    final schools = await listActiveSchools(includeInactive: true);
    return schools.where((school) => ids.contains(school['id'])).toList();
  }

  static Future<void> createSchool(String name) async {
    await _db.collection('schools').add({
      'name': name.trim(),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createClassroom({
    required String schoolId,
    required String grade,
    required String name,
    required String shift,
  }) async {
    await _db.collection('classrooms').add({
      'schoolId': schoolId,
      'grade': grade.trim(),
      'name': name.trim(),
      'shift': shift.trim(),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> listClassrooms(
    String schoolId,
  ) async {
    final rows = await _db
        .collection('classrooms')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final classrooms = rows.docs
        .map(_map)
        .where((classroom) => classroom['active'] == true)
        .toList();
    classrooms.sort((a, b) {
      final gradeComparison = (a['grade'] as String).compareTo(
        b['grade'] as String,
      );
      return gradeComparison == 0
          ? (a['name'] as String).compareTo(b['name'] as String)
          : gradeComparison;
    });
    return classrooms;
  }

  static Future<String> issueTeacherInvite({
    required String schoolId,
    required String email,
  }) async {
    final uid = _uid();
    final code = _randomCode('SQ-');
    await _db.collection('teacherInvites').doc(code).set({
      'schoolId': schoolId,
      'email': email.trim().toLowerCase(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      ),
      'usedBy': null,
    });
    return code;
  }

  static Future<Map<String, dynamic>> redeemTeacherInvite(String code) async {
    final uid = _uid();
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    if (email == null) throw StateError('A conta não possui e-mail.');
    final inviteRef = _db
        .collection('teacherInvites')
        .doc(code.trim().toUpperCase());
    final profileRef = _db.collection('users').doc(uid);

    return _db.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(inviteRef);
      final profileSnapshot = await transaction.get(profileRef);
      final invite = inviteSnapshot.data();
      if (invite == null ||
          invite['email'] != email ||
          invite['usedBy'] != null ||
          !(invite['expiresAt'] as Timestamp).toDate().isAfter(
            DateTime.now(),
          )) {
        throw StateError('Convite inválido, expirado ou já utilizado.');
      }
      final profile = profileSnapshot.data();
      if (profile == null ||
          !{'guardian', 'teacher'}.contains(profile['role'])) {
        throw StateError('Esta conta não pode ser vinculada como educador.');
      }

      final schoolId = invite['schoolId'] as String;
      final membershipRef = _db
          .collection('memberships')
          .doc('${uid}_$schoolId');
      final schoolRef = _db.collection('schools').doc(schoolId);
      final membershipSnapshot = await transaction.get(membershipRef);
      final schoolSnapshot = await transaction.get(schoolRef);
      if (membershipSnapshot.exists) {
        throw StateError('Esta conta já está vinculada a essa escola.');
      }
      if (!schoolSnapshot.exists || schoolSnapshot.data()?['active'] != true) {
        throw StateError('A escola deste convite não está ativa.');
      }
      transaction.update(inviteRef, {
        'usedBy': uid,
        'usedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(profileRef, {
        'role': 'teacher',
        'primarySchoolId': schoolId,
        'redeemedInviteId': inviteRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(membershipRef, {
        'userId': uid,
        'schoolId': schoolId,
        'role': 'teacher',
        'status': 'active',
        'inviteId': inviteRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return {
        'id': schoolId,
        'name': schoolSnapshot.data()?['name'] ?? 'Escola',
      };
    });
  }

  static Future<void> assignSchoolAdministrator({
    required String schoolId,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final emailRow = await _db
        .collection('emailIndex')
        .doc(normalizedEmail)
        .get();
    final uid = emailRow.data()?['uid'] as String?;
    if (uid == null) throw StateError('Crie primeiro a conta desse usuário.');
    final profileRef = _db.collection('users').doc(uid);
    final membershipRef = _db.collection('memberships').doc('${uid}_$schoolId');
    final batch = _db.batch();
    batch.update(profileRef, {
      'role': 'school_admin',
      'primarySchoolId': schoolId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(membershipRef, {
      'userId': uid,
      'schoolId': schoolId,
      'role': 'school_admin',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<void> approveStudent({
    required String studentId,
    required String classroomId,
  }) async {
    final studentRef = _db.collection('students').doc(studentId);
    final classroomRef = _db.collection('classrooms').doc(classroomId);
    final student = await studentRef.get();
    final classroom = await classroomRef.get();
    final schoolId = student.data()?['schoolId'] as String?;
    if (schoolId == null || classroom.data()?['schoolId'] != schoolId) {
      throw StateError('O aluno e a turma precisam pertencer à mesma escola.');
    }

    final enrollmentRef = _db
        .collection('enrollments')
        .doc('${studentId}_$classroomId');
    final batch = _db.batch();
    batch.update(studentRef, {
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(enrollmentRef, {
      'studentId': studentId,
      'schoolId': schoolId,
      'classroomId': classroomId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<Map<String, dynamic>> loadSchoolWorkspace(
    String schoolId,
  ) async {
    final classrooms = await listClassrooms(schoolId);
    final studentsSnapshot = await _db
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final students = studentsSnapshot.docs.map(_map).toList();
    final pending = students
        .where((student) => student['status'] == 'pending')
        .toList();
    final studentById = {
      for (final student in students) student['id']: student,
    };

    final enrollmentSnapshot = await _db
        .collection('enrollments')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final enrollments = enrollmentSnapshot.docs
        .map(_map)
        .where((row) => row['active'] == true)
        .toList();
    final enrolledStudents = enrollments
        .map((row) => studentById[row['studentId']])
        .whereType<Map<String, dynamic>>()
        .toList();
    enrolledStudents.sort(
      (a, b) => (a['fullName'] as String).compareTo(b['fullName'] as String),
    );
    final stats = <String, ({int quizzes, int points})>{};
    for (final studentId in studentById.keys) {
      final sessionRows = await _db
          .collection('students')
          .doc(studentId as String)
          .collection('quizSessions')
          .get();
      stats[studentId] = (
        quizzes: sessionRows.docs.length,
        points: sessionRows.docs.fold<int>(
          0,
          (total, session) =>
              total + ((session.data()['score'] as num?)?.toInt() ?? 0),
        ),
      );
    }
    return {
      'classrooms': classrooms,
      'pendingStudents': pending,
      'enrolledStudents': enrolledStudents,
      'enrollments': enrollments,
      'studentStats': stats,
    };
  }

  static Future<void> createGuardianQuizSession({
    required String studentId,
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> attempts,
  }) async {
    final sessionId = session['client_session_id'] as String;
    final sessionRef = _db
        .collection('students')
        .doc(studentId)
        .collection('quizSessions')
        .doc(sessionId);
    final batch = _db.batch();
    batch.set(sessionRef, {
      'studentId': studentId,
      'clientSessionId': sessionId,
      'subject': session['materia'],
      'grade': session['ano'],
      'topic': session['topico'],
      'score': session['pontuacao'],
      'stars': session['estrelas'],
      'correctAnswers': session['acertos'],
      'totalQuestions': session['total_perguntas'],
      'durationSeconds': session['tempo_segundos'],
      'completedAt': Timestamp.fromDate(
        DateTime.tryParse(session['data_partida'] as String? ?? '') ??
            DateTime.now(),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (var index = 0; index < attempts.length; index++) {
      final attempt = attempts[index];
      batch.set(sessionRef.collection('attempts').doc('$index'), {
        'question': attempt['pergunta'] ?? '',
        'selectedAnswer': attempt['resposta_selecionada'] ?? '',
        'correctAnswer': attempt['resposta_correta'] ?? '',
        'isCorrect': attempt['acertou'] == true,
        'questionOrder': attempt['ordem_pergunta'] ?? index,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
