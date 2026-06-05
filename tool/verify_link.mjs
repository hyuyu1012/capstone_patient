// End-to-end verification of the guardian↔patient Firestore flow, mirroring
// exactly what the two apps do (auth roles, patient creation + invite code,
// claim, guardian schedule write, patient read). Hits the REAL Firebase
// project capstone-2b4a9 via the Auth + Firestore REST APIs.
//
//   node tool/verify_link.mjs
//
// Creates two throwaway auth users + one patient doc + one schedule under it,
// then reports PASS/FAIL per step and prints the ids it created for cleanup.

const API_KEY = 'AIzaSyD80HxPyaKU9VIvOA70jRYxgjndV6eVkfo'; // web key (firebase_options.dart)
const PROJECT = 'capstone-2b4a9';
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const IDTK = 'https://identitytoolkit.googleapis.com/v1/accounts';

const stamp = Date.now();
const log = (ok, msg) => console.log(`${ok ? '✅ PASS' : '❌ FAIL'}  ${msg}`);
let failures = 0;
const check = (cond, msg) => { if (!cond) failures++; log(cond, msg); return cond; };

// ── tiny typed-value helpers for Firestore REST ──
const V = {
  s: (v) => v == null ? { nullValue: null } : { stringValue: v },
  i: (v) => ({ integerValue: String(v) }),
  b: (v) => ({ booleanValue: v }),
  arr: (vals) => ({ arrayValue: { values: vals } }),
};
const decode = (f) => {
  if (f == null) return null;
  if ('stringValue' in f) return f.stringValue;
  if ('integerValue' in f) return Number(f.integerValue);
  if ('booleanValue' in f) return f.booleanValue;
  if ('nullValue' in f) return null;
  if ('arrayValue' in f) return (f.arrayValue.values ?? []).map(decode);
  return f;
};
const decodeDoc = (doc) => Object.fromEntries(
  Object.entries(doc.fields ?? {}).map(([k, v]) => [k, decode(v)]));

async function jpost(url, body, token) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`${res.status} ${JSON.stringify(json)}`);
  return json;
}
async function signUp(role) {
  const email = `${role}.${stamp}@test.ansim`;
  const out = await jpost(`${IDTK}:signUp?key=${API_KEY}`, { email, password: 'test123456', returnSecureToken: true });
  return { uid: out.localId, token: out.idToken, email };
}

function code6() {
  const ab = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => ab[Math.floor(Math.random() * ab.length)]).join('');
}

(async () => {
  console.log(`\n안심 케어 — 연동 검증 (run ${stamp})\n${'─'.repeat(48)}`);

  // 1. Guardian signs up (role: guardian)
  const g = await signUp('guardian');
  await jpost(`${FS}/users?documentId=${g.uid}`, { fields: { email: V.s(g.email), role: V.s('guardian') } }, g.token);
  check(!!g.uid, `보호자 가입 (uid=${g.uid.slice(0, 6)}…, role=guardian)`);

  // 2. Guardian creates a patient with an invite code (PatientService.createPatient)
  const invite = code6();
  const created = await jpost(`${FS}/patients`, {
    fields: {
      name: V.s('테스트 환자'), relation: V.s('어머니'),
      birthYear: V.i(1950), birthMonth: V.i(3), birthDay: V.i(2), gender: V.s('female'),
      userId: V.s(null), guardianIds: V.arr([V.s(g.uid)]), inviteCode: V.s(invite),
    },
  }, g.token);
  const patientId = created.name.split('/').pop();
  check(!!patientId, `환자 생성 (patientId=${patientId.slice(0, 6)}…, inviteCode=${invite})`);

  // 3. Patient signs up (role: patient)
  const p = await signUp('patient');
  await jpost(`${FS}/users?documentId=${p.uid}`, { fields: { email: V.s(p.email), role: V.s('patient') } }, p.token);
  check(!!p.uid, `환자 가입 (uid=${p.uid.slice(0, 6)}…, role=patient)`);

  // 4. Patient claims by invite code → look up by inviteCode, then set userId
  const q = await jpost(`${FS}:runQuery`, {
    structuredQuery: {
      from: [{ collectionId: 'patients' }],
      where: { fieldFilter: { field: { fieldPath: 'inviteCode' }, op: 'EQUAL', value: V.s(invite) } },
      limit: 1,
    },
  }, p.token);
  const found = q.find((r) => r.document)?.document;
  check(found && found.name.split('/').pop() === patientId, `초대코드로 환자 조회 (코드 일치)`);
  // set userId = patient uid (claimByInviteCode)
  await fetch(`${FS}/patients/${patientId}?updateMask.fieldPaths=userId`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${p.token}` },
    body: JSON.stringify({ fields: { userId: V.s(p.uid) } }),
  });

  // 5. Guardian registers a schedule (register sheet → ScheduleService.addSchedule)
  await jpost(`${FS}/patients/${patientId}/schedules`, {
    fields: {
      kind: V.s('med'), name: V.s('혈압약'), dose: V.s('5mg 1정'),
      time: V.s('08:00'), taken: V.b(false), takenAt: V.s(null),
    },
  }, g.token);
  await jpost(`${FS}/patients/${patientId}/schedules`, {
    fields: {
      kind: V.s('meal'), name: V.s('아침'), dose: V.s(null),
      time: V.s('08:30'), taken: V.b(false), takenAt: V.s(null),
    },
  }, g.token);

  // 6. Patient reads back the patient doc + schedules (myPatient + schedulesFor)
  const mineQ = await jpost(`${FS}:runQuery`, {
    structuredQuery: {
      from: [{ collectionId: 'patients' }],
      where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: V.s(p.uid) } },
      limit: 1,
    },
  }, p.token);
  const mine = mineQ.find((r) => r.document)?.document;
  const mineData = mine ? decodeDoc(mine) : {};
  check(mine && mine.name.split('/').pop() === patientId, `환자 앱: 내 환자 조회 (userId=내 uid 로 claim 됨)`);
  check((mineData.guardianIds ?? []).includes(g.uid), `보호자 연결 확인 (guardianIds 에 보호자 포함)`);

  const schRes = await fetch(`${FS}/patients/${patientId}/schedules`, { headers: { Authorization: `Bearer ${p.token}` } });
  const sch = await schRes.json();
  const items = (sch.documents ?? []).map(decodeDoc).sort((a, b) => a.time.localeCompare(b.time));
  check(items.length === 2, `환자 앱: 보호자가 등록한 일정 ${items.length}건 읽힘`);
  items.forEach((it) => console.log(`        · ${it.time}  ${it.name} (${it.kind}${it.dose ? ', ' + it.dose : ''})`));

  console.log('─'.repeat(48));
  console.log(failures === 0 ? '🎉 전체 통과 — 보호자↔환자 연동 + 일정 동기화 정상' : `⚠️  ${failures}건 실패`);
  console.log(`\n생성된 테스트 데이터 (정리용):\n  patients/${patientId}\n  users/${g.uid} (guardian)\n  users/${p.uid} (patient)\n`);
  process.exit(failures === 0 ? 0 : 1);
})().catch((e) => { console.error('스크립트 오류:', e.message); process.exit(2); });
