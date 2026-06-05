// Deletes the throwaway test data left by verify_link.mjs: the test patient doc
// (+ its schedules subcollection) and the two test auth users. Re-derives the
// users by re-authenticating with the known test password, then uses each
// idToken to delete its own account (accounts:delete) — no admin SDK needed.
//
//   node tool/cleanup_verify.mjs <run-stamp>
//
// <run-stamp> is the number printed in verify_link.mjs's header (used to rebuild
// the test emails). The patient id is discovered via the guardian token.

const API_KEY = 'AIzaSyD80HxPyaKU9VIvOA70jRYxgjndV6eVkfo';
const PROJECT = 'capstone-2b4a9';
const FS = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
const IDTK = 'https://identitytoolkit.googleapis.com/v1/accounts';

const stamp = process.argv[2];
if (!stamp) {
  console.error('사용법: node tool/cleanup_verify.mjs <run-stamp>  (verify 출력 상단의 run 숫자)');
  process.exit(2);
}

async function jpost(url, body, token) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(`${res.status} ${JSON.stringify(json)}`);
  return json;
}
async function signIn(role) {
  const email = `${role}.${stamp}@test.ansim`;
  const out = await jpost(`${IDTK}:signInWithPassword?key=${API_KEY}`,
    { email, password: 'test123456', returnSecureToken: true });
  return { uid: out.localId, token: out.idToken, email };
}
async function del(path, token) {
  const res = await fetch(`${FS}/${path}`, { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } });
  return res.ok;
}

(async () => {
  console.log(`\n테스트 데이터 삭제 (run ${stamp})\n${'─'.repeat(40)}`);
  const g = await signIn('guardian');
  const p = await signIn('patient');

  // Find the patient claimed by the test patient (userId == p.uid).
  const q = await jpost(`${FS}:runQuery`, {
    structuredQuery: {
      from: [{ collectionId: 'patients' }],
      where: { fieldFilter: { field: { fieldPath: 'userId' }, op: 'EQUAL', value: { stringValue: p.uid } } },
      limit: 1,
    },
  }, p.token);
  const doc = q.find((r) => r.document)?.document;

  if (doc) {
    const patientId = doc.name.split('/').pop();
    // delete schedules subcollection first
    const schRes = await fetch(`${FS}/patients/${patientId}/schedules`, { headers: { Authorization: `Bearer ${g.token}` } });
    const sch = await schRes.json();
    for (const s of (sch.documents ?? [])) {
      await del(`patients/${patientId}/schedules/${s.name.split('/').pop()}`, g.token);
    }
    console.log(`✅ schedules ${(sch.documents ?? []).length}건 삭제`);
    console.log(await del(`patients/${patientId}`, g.token) ? `✅ patients/${patientId} 삭제` : `❌ patient 삭제 실패`);
  } else {
    console.log('… 매칭되는 patient 문서 없음 (이미 삭제된 듯)');
  }

  console.log(await del(`users/${g.uid}`, g.token) ? '✅ users/(guardian) 삭제' : '❌ guardian users 삭제 실패');
  console.log(await del(`users/${p.uid}`, p.token) ? '✅ users/(patient) 삭제' : '❌ patient users 삭제 실패');

  // delete the two auth accounts (each deletes itself with its own idToken)
  await jpost(`${IDTK}:delete?key=${API_KEY}`, { idToken: g.token });
  console.log('✅ 보호자 테스트 계정 삭제');
  await jpost(`${IDTK}:delete?key=${API_KEY}`, { idToken: p.token });
  console.log('✅ 환자 테스트 계정 삭제');

  console.log('─'.repeat(40));
  console.log('🧹 정리 완료');
})().catch((e) => { console.error('정리 오류:', e.message); process.exit(1); });
