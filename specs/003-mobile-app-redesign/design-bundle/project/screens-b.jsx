// NA-Academy — exam + chat + profile screens

// ─── EXAMS LIST ──────────────────────────────────────────────
function ScreenExams() {
  const available = [
    { title: 'Midterm · Organic Chem', subj: 'Organic Chemistry', q: 20, min: 45, hue: 'secondary', free: false },
    { title: 'Weekly quiz · Week 12', subj: 'Calculus II', q: 10, min: 15, hue: 'accent', free: true },
    { title: 'Grammar check-in', subj: 'Arabic Literature', q: 12, min: 20, hue: 'accent', free: true },
  ];
  const done = [
    { title: 'Chapter 3 quiz', subj: 'Calculus II', score: 88, when: '2 days ago' },
    { title: 'Mechanics placement', subj: 'Physics', score: 72, when: 'last week' },
  ];
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        <div style={{ padding: '12px 4px 16px' }}>
          <div className="t-display na-serif">Exams</div>
          <div className="t-body muted" style={{ marginTop: 6 }}>Three available. One due today.</div>
        </div>

        <div className="section-head"><div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Available</div></div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 24 }}>
          {available.map((e, i) => {
            const hue = e.hue === 'secondary' ? 'var(--secondary)' : 'var(--accent)';
            const soft = e.hue === 'secondary' ? 'var(--secondary-soft)' : 'var(--accent-soft)';
            return (
              <div key={i} className="card" style={{ padding: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10 }}>
                  <div className="t-caption" style={{ color: hue }}>{e.subj}</div>
                  {e.free && <span className="chip" style={{ background: soft, color: hue }}>Free attempt</span>}
                </div>
                <div className="t-h1 na-serif" style={{ fontWeight: 500, marginTop: 6 }}>{e.title}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 14 }}>
                  <span className="t-meta" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}><IconClock size={13} />{e.min} min</span>
                  <span className="t-meta" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}><IconClipboard size={13} />{e.q} questions</span>
                  <div style={{ flex: 1 }} />
                  <button className="btn btn-sm" style={{ background: hue, color: '#fff' }}>Start</button>
                </div>
              </div>
            );
          })}
        </div>

        <div className="section-head"><div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Completed</div></div>
        <div className="row-group">
          {done.map((e, i) => (
            <div key={i} className="row">
              <div style={{ width: 44, height: 44, borderRadius: 999, background: 'var(--bg-sunken)', display: 'grid', placeItems: 'center', fontFamily: 'Fraunces, serif', fontWeight: 600, fontSize: 15, color: e.score >= 80 ? 'var(--success)' : 'var(--text-primary)' }}>{e.score}</div>
              <div style={{ flex: 1 }}>
                <div className="t-body-strong">{e.title}</div>
                <div className="t-meta">{e.subj} · {e.when}</div>
              </div>
              <IconChevronRight size={16} color="var(--text-muted)" />
            </div>
          ))}
        </div>
      </div>
      <TabBar active="exams" />
    </>
  );
}

// ─── EXAM TAKE ───────────────────────────────────────────────
function ScreenExamTake() {
  const [picked, setPicked] = useState('B');
  const opts = [
    { L: 'A', t: 'The electrophile attacks the π bond, forming a carbocation intermediate.' },
    { L: 'B', t: 'A concerted mechanism proceeds through a cyclic bromonium ion.' },
    { L: 'C', t: 'Two separate radical additions occur simultaneously.' },
    { L: 'D', t: 'The halogen first coordinates to the solvent before reacting.' },
  ];
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      {/* sticky timer header */}
      <div style={{ padding: '12px 16px 10px', background: 'var(--bg-canvas)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <button className="ic-wrap" style={{ border: 'none', width: 36, height: 36 }}><IconChevronLeft size={18} /></button>
          <div style={{ flex: 1 }}>
            <div className="t-meta">Question 7 of 20</div>
            <div className="progress-track" style={{ marginTop: 6 }}><div className="progress-fill" style={{ width: '35%' }} /></div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'var(--bg-surface)', boxShadow: 'var(--shadow-card)', padding: '8px 12px', borderRadius: 999, fontVariantNumeric: 'tabular-nums' }}>
            <IconClock size={14} color="var(--accent)" />
            <span className="t-body-strong" style={{ fontSize: 14 }}>28:14</span>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '8px 16px 28px' }}>
        <div className="t-caption" style={{ color: 'var(--secondary)', marginTop: 4 }}>Organic Chemistry · Midterm</div>
        <div className="t-title na-serif" style={{ marginTop: 10 }}>
          Which statement best describes the mechanism of bromine addition to an alkene in a non-polar solvent?
        </div>

        {/* placeholder diagram */}
        <div style={{ marginTop: 16, height: 110, borderRadius: 14, background: 'var(--bg-surface)', boxShadow: 'var(--shadow-card)', position: 'relative', overflow: 'hidden' }}>
          <svg viewBox="0 0 300 110" width="100%" height="100%">
            <line x1="70" y1="55" x2="130" y2="55" stroke="var(--text-primary)" strokeWidth="2" />
            <line x1="70" y1="51" x2="130" y2="51" stroke="var(--text-primary)" strokeWidth="2" />
            <text x="56" y="60" fontFamily="Fraunces" fontSize="20" textAnchor="end" fill="var(--text-primary)">H₂C</text>
            <text x="148" y="60" fontFamily="Fraunces" fontSize="20" fill="var(--text-primary)">CH₂</text>
            <path d="M170 55 Q 200 30 230 55" fill="none" stroke="var(--accent)" strokeWidth="1.5" strokeDasharray="3 3" />
            <text x="210" y="28" fontFamily="Inter" fontSize="11" fill="var(--accent-deep)">+ Br₂</text>
            <text x="260" y="60" fontFamily="Fraunces" fontSize="18" fill="var(--text-muted)">?</text>
          </svg>
        </div>

        {/* options */}
        <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {opts.map(o => {
            const sel = picked === o.L;
            return (
              <div key={o.L} onClick={() => setPicked(o.L)} style={{
                background: sel ? 'var(--accent-soft)' : 'var(--bg-surface)',
                border: `1.5px solid ${sel ? 'var(--accent)' : 'var(--border-subtle)'}`,
                borderRadius: 14, padding: 14, display: 'flex', gap: 12, alignItems: 'flex-start', cursor: 'pointer',
                transition: 'all 160ms',
              }}>
                <div style={{ width: 28, height: 28, borderRadius: 999, background: sel ? 'var(--accent)' : 'var(--bg-sunken)', color: sel ? '#fff' : 'var(--text-secondary)', display: 'grid', placeItems: 'center', fontWeight: 600, fontSize: 13, fontFamily: 'Fraunces, serif', flexShrink: 0 }}>
                  {o.L}
                </div>
                <div className="t-body" style={{ flex: 1, lineHeight: 1.45 }}>{o.t}</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* footer */}
      <div style={{ padding: '14px 16px 30px', display: 'flex', gap: 10, background: 'var(--bg-canvas)', boxShadow: '0 -1px 0 var(--border-subtle)' }}>
        <button className="btn btn-secondary">Skip</button>
        <button className="btn btn-primary btn-accent" style={{ flex: 1 }}>Next question<IconChevronRight size={16} /></button>
      </div>
    </div>
  );
}

// ─── EXAM RESULT ─────────────────────────────────────────────
function ScreenExamResult() {
  const review = [
    { q: 'Mechanism of bromine addition', ok: true },
    { q: 'Markovnikov vs anti-Markovnikov', ok: true },
    { q: 'Stereochemistry of E2', ok: false },
    { q: 'Nucleophile strength ranking', ok: true },
    { q: 'Resonance in carbonyl', ok: false },
  ];
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'auto' }}>
      <Header back title="Result" />
      <div style={{ padding: '8px 16px 40px' }}>
        <div className="card" style={{ padding: 24, textAlign: 'center' }}>
          <div className="t-caption" style={{ color: 'var(--accent)' }}>Midterm · Organic Chem</div>
          <div style={{ margin: '18px auto 8px' }}>
            <Ring value={84} size={148} stroke={10}>
              <div style={{ textAlign: 'center' }}>
                <div className="na-serif" style={{ fontSize: 44, fontWeight: 500, lineHeight: 1 }}>84</div>
                <div className="t-caption muted" style={{ marginTop: 2 }}>of 100</div>
              </div>
            </Ring>
          </div>
          <div className="t-h1 na-serif" style={{ fontWeight: 500, marginTop: 6 }}>Good work, Layla.</div>
          <div className="t-body muted" style={{ marginTop: 6 }}>You beat 72% of students this week.</div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 14 }}>
          {[['17', 'correct', 'var(--success)'], ['3', 'missed', 'var(--danger)'], ['41m', 'spent', 'var(--text-primary)']].map(([n, l, c], i) => (
            <div key={i} className="card-flat" style={{ textAlign: 'center', padding: '12px 8px' }}>
              <div className="t-h1 na-serif" style={{ fontWeight: 500, color: c }}>{n}</div>
              <div className="t-meta" style={{ marginTop: 2 }}>{l}</div>
            </div>
          ))}
        </div>

        <div className="section-head" style={{ marginTop: 22 }}>
          <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Review</div>
          <a className="action">See all</a>
        </div>
        <div className="row-group">
          {review.map((r, i) => (
            <div key={i} className="row">
              <div style={{ width: 28, height: 28, borderRadius: 999, background: r.ok ? 'color-mix(in oklab, var(--success), transparent 80%)' : 'var(--danger-soft)', color: r.ok ? 'var(--success)' : 'var(--danger)', display: 'grid', placeItems: 'center' }}>
                {r.ok ? <IconCheck size={14} /> : <span style={{ fontWeight: 700, fontSize: 14 }}>×</span>}
              </div>
              <div style={{ flex: 1 }}>
                <div className="t-body">{r.q}</div>
              </div>
              <IconChevronRight size={16} color="var(--text-muted)" />
            </div>
          ))}
        </div>

        <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
          <button className="btn btn-secondary" style={{ flex: 1 }}>Download certificate</button>
          <button className="btn btn-primary btn-accent" style={{ flex: 1 }}>Next exam</button>
        </div>
      </div>
    </div>
  );
}

// ─── CHAT LIST ───────────────────────────────────────────────
function ScreenChatList() {
  const rows = [
    { name: 'Mr. Omar Khalil', role: 'Chem tutor', msg: 'Good catch on the bromonium — send me the next page when you can.', t: '2m', unread: 2, online: true },
    { name: 'Ms. Rana Haddad', role: 'Math tutor', msg: 'You: Got it, will try the u-sub tonight.', t: '1h', unread: 0, online: false },
    { name: 'Study group · Physics', role: '4 people', msg: 'Sami: anyone free Sat morning?', t: '3h', unread: 5, online: true },
    { name: 'Ms. Dana Saad', role: 'Arabic lit', msg: 'Your essay came back with notes — overall very strong.', t: 'yest', unread: 0, online: false },
    { name: 'Support', role: 'NA-Academy', msg: 'We\'ve activated your premium access.', t: 'Mon', unread: 0, online: false },
  ];
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        <div style={{ padding: '12px 4px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
          <div>
            <div className="t-display na-serif">Messages</div>
            <div className="t-body muted" style={{ marginTop: 6 }}>Your tutors and study groups.</div>
          </div>
          <button className="ic-wrap ic-wrap-accent" style={{ border: 'none', width: 42, height: 42, borderRadius: 14 }}>
            <IconPlus size={18} />
          </button>
        </div>

        <div className="card-sunken" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 14px', marginBottom: 14 }}>
          <IconSearch size={16} color="var(--text-muted)" />
          <input placeholder="Search conversations" style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: 'var(--text-primary)', fontFamily: 'inherit' }} />
        </div>

        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {rows.map((r, i) => (
            <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-start', padding: '14px 4px', borderBottom: i < rows.length - 1 ? '1px solid var(--border-subtle)' : 'none', cursor: 'pointer' }}>
              <div style={{ position: 'relative' }}>
                <div className="avatar" style={{ width: 48, height: 48, fontSize: 16, background: i % 2 ? 'var(--secondary-soft)' : 'var(--accent-soft)', color: i % 2 ? 'var(--secondary)' : 'var(--accent-deep)' }}>
                  {r.name.split(' ').map(w => w[0]).slice(0, 2).join('').replace('.', '')}
                </div>
                {r.online && <div style={{ position: 'absolute', bottom: 0, right: 0, width: 12, height: 12, borderRadius: 999, background: 'var(--success)', border: '2px solid var(--bg-canvas)' }} />}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, alignItems: 'baseline' }}>
                  <div className="t-body-strong" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                  <div className="t-meta" style={{ flexShrink: 0 }}>{r.t}</div>
                </div>
                <div className="t-meta" style={{ marginTop: 1 }}>{r.role}</div>
                <div className="t-sm muted" style={{ marginTop: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: r.unread ? 'var(--text-primary)' : 'var(--text-secondary)', fontWeight: r.unread ? 500 : 400 }}>
                  {r.msg}
                </div>
              </div>
              {r.unread > 0 && (
                <div style={{ minWidth: 22, height: 22, padding: '0 7px', borderRadius: 999, background: 'var(--accent)', color: '#fff', display: 'grid', placeItems: 'center', fontSize: 11, fontWeight: 600, marginTop: 20 }}>
                  {r.unread}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
      <TabBar active="chat" />
    </>
  );
}

// ─── CHAT THREAD ─────────────────────────────────────────────
function ScreenChatThread() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      {/* header */}
      <div style={{ padding: '8px 16px 12px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: '1px solid var(--border-subtle)' }}>
        <button className="ic-wrap" style={{ border: 'none', width: 36, height: 36 }}><IconChevronLeft size={18} /></button>
        <div className="avatar" style={{ width: 36, height: 36, fontSize: 13, background: 'var(--accent-soft)', color: 'var(--accent-deep)' }}>OK</div>
        <div style={{ flex: 1 }}>
          <div className="t-body-strong" style={{ fontSize: 14 }}>Mr. Omar Khalil</div>
          <div className="t-meta" style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--success)' }} />
            Online · Chem tutor
          </div>
        </div>
        <button className="ic-wrap" style={{ border: 'none', width: 36, height: 36 }}><IconMore size={18} /></button>
      </div>

      {/* messages */}
      <div style={{ flex: 1, overflow: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ alignSelf: 'center' }} className="t-meta">Today · 3:42 PM</div>

        {/* tutor */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end', maxWidth: '85%' }}>
          <div className="avatar" style={{ width: 28, height: 28, fontSize: 11, background: 'var(--accent-soft)', color: 'var(--accent-deep)' }}>OK</div>
          <div>
            <div style={{ background: 'var(--bg-surface)', padding: '10px 14px', borderRadius: '16px 16px 16px 6px', boxShadow: 'var(--shadow-card)', fontSize: 14, lineHeight: 1.5 }}>
              Hey Layla — how did the bromonium question feel on the practice set?
            </div>
          </div>
        </div>

        {/* me */}
        <div style={{ alignSelf: 'flex-end', maxWidth: '80%' }}>
          <div style={{ background: 'var(--accent)', color: '#fff', padding: '10px 14px', borderRadius: '16px 16px 6px 16px', fontSize: 14, lineHeight: 1.5 }}>
            Mostly okay — I got stuck on why it's a concerted mechanism and not two steps.
          </div>
          <div className="t-meta" style={{ textAlign: 'right', marginTop: 4, display: 'flex', justifyContent: 'flex-end', gap: 4, alignItems: 'center' }}>
            3:43 PM <IconCheck size={12} /><IconCheck size={12} style={{ marginLeft: -8 }} />
          </div>
        </div>

        {/* image from me */}
        <div style={{ alignSelf: 'flex-end', maxWidth: '75%' }}>
          <div style={{ borderRadius: 16, overflow: 'hidden', boxShadow: 'var(--shadow-card)' }}>
            <div className="placeholder" style={{ height: 140, borderRadius: 0, border: 'none' }}>
              <span>photo · my notes p.14</span>
            </div>
          </div>
        </div>

        {/* tutor reply */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end', maxWidth: '85%' }}>
          <div className="avatar" style={{ width: 28, height: 28, fontSize: 11, background: 'var(--accent-soft)', color: 'var(--accent-deep)' }}>OK</div>
          <div style={{ background: 'var(--bg-surface)', padding: '12px 14px', borderRadius: '16px 16px 16px 6px', boxShadow: 'var(--shadow-card)', fontSize: 14, lineHeight: 1.55 }}>
            Good question. The bromine gets polarized as it approaches the π cloud — by the time a full bond forms, the other end is <em>already</em> attacking the back of the carbon. There's never a real carbocation. Look at page 214 fig. 8-3 — the dashed lines show partial bonds forming in parallel.
          </div>
        </div>

        {/* typing */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'center', maxWidth: '85%' }}>
          <div className="avatar" style={{ width: 28, height: 28, fontSize: 11, background: 'var(--accent-soft)', color: 'var(--accent-deep)' }}>OK</div>
          <div style={{ background: 'var(--bg-surface)', padding: '12px 16px', borderRadius: 16, boxShadow: 'var(--shadow-card)' }}>
            <span className="typing"><span/><span/><span/></span>
          </div>
        </div>
      </div>

      {/* composer */}
      <div style={{ padding: '10px 12px 24px', borderTop: '1px solid var(--border-subtle)', background: 'var(--bg-canvas)' }}>
        <div style={{ background: 'var(--bg-surface)', borderRadius: 24, boxShadow: 'var(--shadow-card)', padding: '6px 8px 6px 14px', display: 'flex', alignItems: 'center', gap: 6 }}>
          <button className="ic-wrap" style={{ border: 'none', background: 'transparent', width: 32, height: 32 }}><IconPaperclip size={18} color="var(--text-secondary)" /></button>
          <input placeholder="Message Mr. Omar…" style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 15, padding: '8px 4px', fontFamily: 'inherit', color: 'var(--text-primary)' }} />
          <button style={{ border: 'none', width: 38, height: 38, borderRadius: 999, background: 'var(--accent)', color: '#fff', display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
            <IconSend size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── PROFILE ─────────────────────────────────────────────────
function ScreenProfile() {
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        <div style={{ padding: '12px 4px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div className="t-display na-serif">You</div>
          <button className="ic-wrap" style={{ border: 'none', width: 40, height: 40, background: 'var(--bg-surface)', boxShadow: 'var(--shadow-card)' }}>
            <IconSettings size={18} />
          </button>
        </div>

        {/* profile card */}
        <div className="card" style={{ padding: 20, display: 'flex', gap: 16, alignItems: 'center', marginBottom: 14 }}>
          <div className="avatar" style={{ width: 64, height: 64, fontSize: 22, background: 'var(--accent)', color: '#fff' }}>L</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="t-h1 na-serif" style={{ fontWeight: 500 }}>Layla Ahmed</div>
            <div className="t-meta">layla.ahmed@na-academy.org</div>
            <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
              <span className="chip chip-accent">Student</span>
              <span className="chip chip-secondary">Premium</span>
            </div>
          </div>
        </div>

        {/* stat tiles */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 20 }}>
          <div className="card" style={{ padding: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div className="ic-wrap ic-wrap-secondary" style={{ width: 32, height: 32 }}><IconFlame size={16} /></div>
              <div className="t-caption">Streak</div>
            </div>
            <div className="t-display na-serif" style={{ fontSize: 28, marginTop: 8 }}>12<span className="t-body muted"> days</span></div>
          </div>
          <div className="card" style={{ padding: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div className="ic-wrap ic-wrap-accent" style={{ width: 32, height: 32 }}><IconTrophy size={16} /></div>
              <div className="t-caption">Avg. score</div>
            </div>
            <div className="t-display na-serif" style={{ fontSize: 28, marginTop: 8 }}>86<span className="t-body muted"> %</span></div>
          </div>
        </div>

        {/* analytics mini-chart */}
        <div className="card" style={{ marginBottom: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>This week</div>
            <a className="action">Full analytics</a>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: 90, marginTop: 16, padding: '0 4px' }}>
            {[0.3, 0.55, 0.4, 0.8, 0.65, 0.9, 0.45].map((v, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ width: '100%', height: `${v * 100}%`, background: i === 5 ? 'var(--accent)' : 'var(--accent-soft)', borderRadius: 6 }} />
                <div className="t-meta" style={{ fontSize: 10 }}>{['M','T','W','T','F','S','S'][i]}</div>
              </div>
            ))}
          </div>
        </div>

        {/* list */}
        <div className="row-group">
          {[
            { ic: IconSparkle, label: 'Activate premium', hint: 'Unlock all exams', accent: true },
            { ic: IconTrophy, label: 'Certificates', hint: '3 earned' },
            { ic: IconBookmark, label: 'Saved lessons', hint: '14 items' },
            { ic: IconBell, label: 'Notifications', hint: 'Daily 7:00 PM' },
            { ic: IconMoon, label: 'Appearance', hint: 'System' },
            { ic: IconGlobe, label: 'Language', hint: 'English · العربية' },
          ].map((r, i) => {
            const I = r.ic;
            return (
              <div key={i} className="row">
                <div className={`ic-wrap ${r.accent ? 'ic-wrap-accent' : ''}`}><I size={16} /></div>
                <div style={{ flex: 1 }}>
                  <div className="t-body">{r.label}</div>
                </div>
                <div className="t-meta">{r.hint}</div>
                <IconChevronRight size={16} color="var(--text-muted)" />
              </div>
            );
          })}
        </div>

        <button className="btn btn-ghost btn-block" style={{ marginTop: 20, color: 'var(--danger)' }}>
          <IconLogout size={16} /> Sign out
        </button>
      </div>
      <TabBar active="profile" />
    </>
  );
}

Object.assign(window, { ScreenExams, ScreenExamTake, ScreenExamResult, ScreenChatList, ScreenChatThread, ScreenProfile });
