import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-sqeducaplay';
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  if (testEnvironment) await testEnvironment.cleanup();
});

async function seed(documents) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [path, data] of Object.entries(documents)) {
      await setDoc(doc(db, path), data);
    }
  });
}

test('allows a student-role account to create its own profile and indexes', async () => {
  await seed({
    'users/student-1': { uid: 'student-1', role: 'student', email: 'student@example.com' },
  });
  const db = testEnvironment
    .authenticatedContext('student-1', { email: 'student@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'students/student-1'), {
    ownerUid: 'student-1',
    guardianId: null,
    username: 'aluno-1',
    fullName: 'Aluno Um',
    nickname: null,
    grade: '4º Ano Fundamental',
    schoolId: null,
    status: 'active',
    studentCode: 'ALU-1',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'studentCodes/ALU-1'), {
    studentId: 'student-1',
    ownerUid: 'student-1',
    fullName: 'Aluno Um',
    grade: '4º Ano Fundamental',
    schoolId: null,
    createdAt: serverTimestamp(),
  });
  batch.set(doc(db, 'studentUsernames/aluno-1'), {
    studentId: 'student-1',
    ownerUid: 'student-1',
    guardianId: null,
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test('does not allow a guardian to create a self-owned student profile', async () => {
  await seed({
    'users/guardian-1': { uid: 'guardian-1', role: 'guardian', email: 'guardian@example.com' },
  });
  const db = testEnvironment
    .authenticatedContext('guardian-1', { email: 'guardian@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'students/guardian-1'), {
    ownerUid: 'guardian-1',
    guardianId: null,
    username: 'aluno-falso',
    fullName: 'Perfil indevido',
    nickname: null,
    grade: '4º Ano Fundamental',
    schoolId: null,
    status: 'active',
    studentCode: 'ALU-FALSO',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'studentUsernames/aluno-falso'), {
    studentId: 'guardian-1',
    ownerUid: 'guardian-1',
    guardianId: null,
    createdAt: serverTimestamp(),
  });
  await assertFails(batch.commit());
});

test('allows a guardian to create an authorized child profile and consent', async () => {
  await seed({
    'users/guardian-1': { uid: 'guardian-1', role: 'guardian', email: 'guardian@example.com' },
  });
  const db = testEnvironment
    .authenticatedContext('guardian-1', { email: 'guardian@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, 'students/child-1'), {
    ownerUid: null,
    guardianId: 'guardian-1',
    username: 'child-one',
    fullName: 'Child One',
    nickname: null,
    grade: '3º Ano Fundamental',
    schoolId: null,
    status: 'active',
    studentCode: null,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'students/child-1/consents/consent-1'), {
    guardianId: 'guardian-1',
    version: '1',
    consentedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'studentUsernames/child-one'), {
    studentId: 'child-1',
    ownerUid: null,
    guardianId: 'guardian-1',
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());

  const stranger = testEnvironment
    .authenticatedContext('guardian-2', { email: 'other@example.com' })
    .firestore();
  await assertFails(getDoc(doc(stranger, 'students/child-1')));
});

test('lets a school teacher approve a pending student in the teacher school', async () => {
  await seed({
    'users/teacher-1': { uid: 'teacher-1', role: 'teacher', email: 'teacher@example.com' },
    'memberships/teacher-1_school-1': {
      userId: 'teacher-1',
      schoolId: 'school-1',
      role: 'teacher',
      status: 'active',
    },
    'schools/school-1': { name: 'Escola Um', active: true },
    'classrooms/class-1': {
      schoolId: 'school-1',
      grade: '4º Ano Fundamental',
      name: 'Turma A',
      shift: 'Manhã',
      active: true,
    },
    'students/child-1': {
      ownerUid: null,
      guardianId: 'guardian-1',
      username: 'child-one',
      fullName: 'Child One',
      nickname: null,
      grade: '4º Ano Fundamental',
      schoolId: 'school-1',
      status: 'pending',
    },
  });
  const db = testEnvironment
    .authenticatedContext('teacher-1', { email: 'teacher@example.com' })
    .firestore();
  const batch = writeBatch(db);
  batch.update(doc(db, 'students/child-1'), {
    status: 'active',
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'enrollments/child-1_class-1'), {
    studentId: 'child-1',
    schoolId: 'school-1',
    classroomId: 'class-1',
    active: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test('redeems a teacher invite only with the profile and membership updates together', async () => {
  await seed({
    'users/guardian-1': {
      uid: 'guardian-1',
      role: 'guardian',
      email: 'teacher@example.com',
    },
    'schools/school-1': { name: 'Escola Um', active: true },
    'teacherInvites/SQ-INVITE': {
      schoolId: 'school-1',
      email: 'teacher@example.com',
      createdBy: 'school-admin',
      createdAt: Timestamp.now(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + 86400000)),
      usedBy: null,
    },
  });
  const db = testEnvironment
    .authenticatedContext('guardian-1', { email: 'teacher@example.com' })
    .firestore();
  await assertFails(
    updateDoc(doc(db, 'teacherInvites/SQ-INVITE'), {
      usedBy: 'guardian-1',
      usedAt: serverTimestamp(),
    }),
  );

  const batch = writeBatch(db);
  batch.update(doc(db, 'teacherInvites/SQ-INVITE'), {
    usedBy: 'guardian-1',
    usedAt: serverTimestamp(),
  });
  batch.update(doc(db, 'users/guardian-1'), {
    role: 'teacher',
    primarySchoolId: 'school-1',
    redeemedInviteId: 'SQ-INVITE',
    updatedAt: serverTimestamp(),
  });
  batch.set(doc(db, 'memberships/guardian-1_school-1'), {
    userId: 'guardian-1',
    schoolId: 'school-1',
    role: 'teacher',
    status: 'active',
    inviteId: 'SQ-INVITE',
    createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
});

test('a guardian linked to an independent student has read-only quiz access', async () => {
  await seed({
    'users/guardian-1': { uid: 'guardian-1', role: 'guardian', email: 'guardian@example.com' },
    'users/student-1': { uid: 'student-1', role: 'student', email: 'student@example.com' },
    'students/student-1': {
      ownerUid: 'student-1',
      guardianId: null,
      username: 'student-one',
      fullName: 'Student One',
      grade: '4º Ano Fundamental',
      schoolId: null,
      status: 'active',
    },
    'studentLinks/guardian-1_student-1': {
      guardianId: 'guardian-1',
      studentId: 'student-1',
      code: 'ALU-1',
    },
  });
  const db = testEnvironment
    .authenticatedContext('guardian-1', { email: 'guardian@example.com' })
    .firestore();
  await assertSucceeds(getDoc(doc(db, 'students/student-1')));
  await assertFails(
    setDoc(doc(db, 'students/student-1/quizSessions/session-1'), {
      studentId: 'student-1',
      clientSessionId: 'session-1',
      subject: 'Matemática',
      grade: '4º Ano Fundamental',
      topic: 'Adição',
      score: 10,
      stars: 1,
      correctAnswers: 1,
      totalQuestions: 1,
      durationSeconds: 10,
      completedAt: serverTimestamp(),
      createdAt: serverTimestamp(),
    }),
  );
});

test('prevents one user from reading or deleting another account profile', async () => {
  await seed({
    'users/owner-1': { uid: 'owner-1', role: 'guardian', email: 'owner@example.com' },
  });
  const stranger = testEnvironment
    .authenticatedContext('stranger-1', { email: 'stranger@example.com' })
    .firestore();
  await assertFails(getDoc(doc(stranger, 'users/owner-1')));
  await assertFails(deleteDoc(doc(stranger, 'users/owner-1')));
});

test('allows an account owner to remove their Firebase account records', async () => {
  await seed({
    'users/guardian-1': {
      uid: 'guardian-1',
      role: 'guardian',
      email: 'guardian@example.com',
    },
    'emailIndex/guardian@example.com': {
      uid: 'guardian-1',
      email: 'guardian@example.com',
    },
    'students/child-1': {
      ownerUid: null,
      guardianId: 'guardian-1',
      username: 'child-one',
      fullName: 'Child One',
      grade: '3º Ano Fundamental',
      schoolId: null,
      status: 'active',
    },
    'students/child-1/consents/consent-1': {
      guardianId: 'guardian-1',
      version: '1',
    },
    'studentUsernames/child-one': {
      studentId: 'child-1',
      ownerUid: null,
      guardianId: 'guardian-1',
    },
    'teacherInvites/invite-self': {
      schoolId: 'school-1',
      email: 'guardian@example.com',
      createdBy: 'school-admin',
      usedBy: 'guardian-1',
    },
  });
  const db = testEnvironment
    .authenticatedContext('guardian-1', { email: 'guardian@example.com' })
    .firestore();
  const ownInvites = await assertSucceeds(
    getDocs(
      query(
        collection(db, 'teacherInvites'),
        where('email', '==', 'guardian@example.com'),
      ),
    ),
  );
  assert.equal(ownInvites.size, 1);
  const batch = writeBatch(db);
  batch.delete(doc(db, 'students/child-1/consents/consent-1'));
  batch.delete(doc(db, 'studentUsernames/child-one'));
  batch.delete(doc(db, 'students/child-1'));
  batch.delete(doc(db, 'teacherInvites/invite-self'));
  batch.delete(doc(db, 'emailIndex/guardian@example.com'));
  batch.delete(doc(db, 'users/guardian-1'));
  await assertSucceeds(batch.commit());
});
