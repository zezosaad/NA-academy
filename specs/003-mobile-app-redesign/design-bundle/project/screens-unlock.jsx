// NA-Academy — unlock screens (subject code + exam code)

// ─── UNLOCK SUBJECT (code entry) ─────────────────────────────
function ScreenUnlockSubject() {
  const [code, setCode] = useState(['', '', '', '', '', '']);
  const [err, setErr] = useState(false);
  const refs = useRef([]);

  const set = (i, v) => {
    v = v.replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 1);
    const next = [...code];
    next[i] = v;
    setCode(next);
    setErr(false);
    if (v && i < 5) refs.current[i + 1]?.focus();
  };
  const onKey = (i, e) => {
    if (e.key === 'Backspace' && !code[i] && i > 0) refs.current[i - 1]?.focus();
  };
  const full = code.join('');
  const tryUnlock = () => {
    if (full.length < 6) { setErr(true); return; }
    // demo: anything that isn't the "valid" one fails
    if (full !== 'NA24CH') setErr(true);
    else setErr('ok');
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '24px 24px 28px' }}>
      <button className="ic-wrap" style={{ border: 'none', cursor: 'pointer', width: 40, height: 40 }}>
        <IconChevronLeft size={20} />
      </button>

      <div style={{ marginTop: 28 }}>
        <div style={{ width: 64, height: 64, borderRadius: 20, background: 'var(--accent-soft)', color: 'var(--accent-deep)', display: 'grid', placeItems: 'center' }}>
          <IconLock size={26} />
        </div>
        <div className="t-caption" style={{ color: 'var(--accent)', marginTop: 22 }}>Subject access</div>
        <div className="t-display na-serif" style={{ marginTop: 10 }}>Enter your<br/>subject code.</div>
        <div className="t-body muted" style={{ marginTop: 12, maxWidth: 320 }}>
          Your teacher shared a 6-character code. Type it below to unlock the subject and all its lessons.
        </div>
      </div>

      {/* code inputs */}
      <div style={{ marginTop: 30, display: 'flex', gap: 8, justifyContent: 'space-between' }}>
        {code.map((c, i) => (
          <input
            key={i}
            ref={el => (refs.current[i] = el)}
            value={c}
            onChange={(e) => set(i, e.target.value)}
            onKeyDown={(e) => onKey(i, e)}
            maxLength={1}
            style={{
              width: 46, height: 58, borderRadius: 14,
              border: `1.5px solid ${err === true ? 'var(--danger)' : (c ? 'var(--accent)' : 'var(--border-subtle)')}`,
              background: 'var(--bg-surface)', textAlign: 'center',
              fontFamily: 'Fraunces, serif', fontSize: 26, fontWeight: 500,
              color: 'var(--text-primary)', outline: 'none',
              transition: 'all 140ms', caretColor: 'var(--accent)',
            }}
          />
        ))}
      </div>
      {err === true && (
        <div className="t-sm" style={{ color: 'var(--danger)', marginTop: 12, display: 'flex', gap: 6, alignItems: 'center' }}>
          <span style={{ width: 14, height: 14, borderRadius: 999, background: 'var(--danger)', color: '#fff', display: 'grid', placeItems: 'center', fontSize: 10, fontWeight: 700 }}>!</span>
          That code doesn't match. Double-check with your teacher.
        </div>
      )}
      {err === 'ok' && (
        <div className="t-sm" style={{ color: 'var(--success)', marginTop: 12, display: 'flex', gap: 6, alignItems: 'center' }}>
          <IconCheck size={14} /> Code accepted — unlocking Organic Chemistry.
        </div>
      )}

      <div style={{ flex: 1 }} />

      {/* help card */}
      <div className="card-flat" style={{ display: 'flex', gap: 12, alignItems: 'flex-start', marginBottom: 14 }}>
        <div className="ic-wrap ic-wrap-accent" style={{ width: 32, height: 32 }}><IconChat size={15} /></div>
        <div style={{ flex: 1 }}>
          <div className="t-body-strong" style={{ fontSize: 14 }}>Don't have a code?</div>
          <div className="t-meta" style={{ marginTop: 2 }}>Ask your teacher, or message support.</div>
        </div>
        <IconChevronRight size={16} color="var(--text-muted)" />
      </div>

      <button className="btn btn-primary btn-accent btn-block" onClick={tryUnlock}>
        {err === 'ok' ? 'Unlocked — continue' : 'Unlock subject'}
      </button>
      <button className="btn btn-ghost btn-block" style={{ marginTop: 6 }}>Paste from clipboard</button>
    </div>
  );
}

// ─── UNLOCK EXAM (code entry — compact, inline) ──────────────
function ScreenUnlockExam() {
  const [code, setCode] = useState('');
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      <Header back title="" />
      <div style={{ padding: '0 24px 28px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* locked exam summary card */}
        <div className="card" style={{ padding: 18, marginTop: 4 }}>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <div className="ic-wrap ic-wrap-secondary" style={{ width: 44, height: 44 }}><IconClipboard size={20} /></div>
            <div style={{ flex: 1 }}>
              <div className="t-caption" style={{ color: 'var(--secondary)' }}>Organic Chemistry</div>
              <div className="t-h2 na-serif" style={{ fontWeight: 500, marginTop: 2 }}>Midterm · Chapter 8</div>
            </div>
            <div style={{ width: 36, height: 36, borderRadius: 999, background: 'var(--bg-sunken)', display: 'grid', placeItems: 'center', color: 'var(--text-muted)' }}>
              <IconLock size={16} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 14, marginTop: 14, paddingTop: 14, borderTop: '1px solid var(--border-subtle)' }}>
            <span className="t-meta" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}><IconClock size={13} />45 min</span>
            <span className="t-meta" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}><IconClipboard size={13} />20 questions</span>
            <span className="t-meta" style={{ display: 'inline-flex', alignItems: 'center', gap: 5 }}><IconTrophy size={13} />1 attempt</span>
          </div>
        </div>

        <div style={{ marginTop: 28 }}>
          <div className="t-caption" style={{ color: 'var(--accent)' }}>Exam access</div>
          <div className="t-title na-serif" style={{ marginTop: 8 }}>Enter exam code to begin.</div>
          <div className="t-body muted" style={{ marginTop: 10 }}>
            The proctor or teacher will read the code aloud when the session starts.
          </div>
        </div>

        {/* single wide input */}
        <div style={{ marginTop: 22 }}>
          <div className="field-label" style={{ marginBottom: 6 }}>Exam code</div>
          <div style={{ position: 'relative' }}>
            <input
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase().replace(/[^A-Z0-9-]/g, ''))}
              placeholder="e.g. EXM-7241"
              style={{
                width: '100%', boxSizing: 'border-box',
                padding: '18px 54px 18px 18px',
                borderRadius: 16, border: '1.5px solid var(--border-subtle)',
                background: 'var(--bg-surface)', outline: 'none',
                fontFamily: 'JetBrains Mono, ui-monospace, monospace',
                fontSize: 22, letterSpacing: '0.18em',
                color: 'var(--text-primary)', textAlign: 'center',
              }}
            />
            {code && (
              <button onClick={() => setCode('')} aria-label="clear" style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', border: 'none', background: 'var(--bg-sunken)', width: 28, height: 28, borderRadius: 999, display: 'grid', placeItems: 'center', cursor: 'pointer', color: 'var(--text-secondary)', fontSize: 14 }}>×</button>
            )}
          </div>
          <div className="t-meta" style={{ marginTop: 8 }}>Codes are case-insensitive · hyphens optional.</div>
        </div>

        {/* rules */}
        <div style={{ marginTop: 24 }}>
          <div className="t-caption" style={{ marginBottom: 10 }}>Before you start</div>
          <div className="row-group">
            {[
              { ic: IconClock, t: 'Timer starts immediately.', s: "You can't pause once you begin." },
              { ic: IconLock, t: 'Single attempt only.', s: 'Closing the app submits what you have.' },
              { ic: IconCheck, t: 'Calm space, good signal.', s: 'Answers auto-save every 10 seconds.' },
            ].map((r, i) => {
              const I = r.ic;
              return (
                <div key={i} className="row">
                  <div className="ic-wrap"><I size={15} /></div>
                  <div style={{ flex: 1 }}>
                    <div className="t-body" style={{ fontWeight: 500 }}>{r.t}</div>
                    <div className="t-meta">{r.s}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div style={{ flex: 1 }} />

        <button
          className="btn btn-primary btn-accent btn-block"
          style={{ marginTop: 20, opacity: code.length >= 4 ? 1 : 0.45, pointerEvents: code.length >= 4 ? 'auto' : 'none' }}
        >
          Unlock and start exam
        </button>
        <button className="btn btn-ghost btn-block" style={{ marginTop: 6, color: 'var(--text-secondary)' }}>
          Cancel
        </button>
      </div>
    </div>
  );
}

// ─── LOCKED SUBJECTS GRID (shows padlock state + CTA) ────────
function ScreenSubjectsLocked() {
  const items = [
    { title: 'Calculus II', cat: 'Math', prog: 68, hue: 'accent', locked: false, lessons: 18 },
    { title: 'Modern Arabic Lit', cat: 'Languages', prog: 84, hue: 'accent', locked: false, lessons: 18 },
    { title: 'Organic Chemistry', cat: 'Science', hue: 'secondary', locked: true, lessons: 20 },
    { title: 'Physics · Mechanics', cat: 'Science', hue: 'accent', locked: true, lessons: 16 },
    { title: 'World History', cat: 'Arts', hue: 'secondary', locked: true, lessons: 22 },
    { title: 'Linear Algebra', cat: 'Math', hue: 'accent', locked: true, lessons: 14 },
  ];
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        <div style={{ padding: '12px 4px 16px' }}>
          <div className="t-display na-serif">Learn</div>
          <div className="t-body muted" style={{ marginTop: 6 }}>Two unlocked. Enter a code to open more.</div>
        </div>

        {/* Code CTA card — prominent */}
        <div style={{
          background: 'linear-gradient(135deg, var(--accent-soft), var(--bg-surface))',
          borderRadius: 18, padding: 16, marginBottom: 18,
          boxShadow: 'var(--shadow-card)', display: 'flex', gap: 14, alignItems: 'center',
        }}>
          <div style={{ width: 46, height: 46, borderRadius: 14, background: 'var(--accent)', color: '#fff', display: 'grid', placeItems: 'center' }}>
            <IconLock size={20} />
          </div>
          <div style={{ flex: 1 }}>
            <div className="t-body-strong">Have a subject code?</div>
            <div className="t-meta" style={{ marginTop: 2 }}>Unlock a new subject with 6 characters.</div>
          </div>
          <button className="btn btn-sm btn-primary btn-accent">Enter code</button>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {items.map((s, i) => {
            const hue = s.hue === 'secondary' ? 'var(--secondary)' : 'var(--accent)';
            const soft = s.hue === 'secondary' ? 'var(--secondary-soft)' : 'var(--accent-soft)';
            return (
              <div key={i} className="card" style={{ padding: 14, position: 'relative', opacity: s.locked ? 0.95 : 1 }}>
                <div style={{ height: 60, borderRadius: 12, background: s.locked ? 'var(--bg-sunken)' : soft, marginBottom: 12, position: 'relative', overflow: 'hidden', display: 'grid', placeItems: 'center' }}>
                  {s.locked ? (
                    <div style={{ color: 'var(--text-muted)' }}><IconLock size={22} /></div>
                  ) : (
                    <svg viewBox="0 0 100 60" width="100%" height="100%" preserveAspectRatio="none">
                      <path d={`M 0 ${40} Q 25 20 50 30 T 100 25`} fill="none" stroke={hue} strokeWidth="1" opacity="0.6" />
                    </svg>
                  )}
                </div>
                <div className="t-caption" style={{ color: s.locked ? 'var(--text-muted)' : hue, marginBottom: 6 }}>{s.cat}</div>
                <div className="t-h2 na-serif" style={{ fontWeight: 500, minHeight: 44, color: s.locked ? 'var(--text-secondary)' : 'var(--text-primary)' }}>{s.title}</div>
                <div style={{ marginTop: 10 }}>
                  {s.locked ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 10px', borderRadius: 999, background: 'var(--bg-sunken)', width: 'fit-content' }}>
                      <IconLock size={12} color="var(--text-muted)" />
                      <span className="t-meta" style={{ fontSize: 11, fontWeight: 500 }}>Needs code</span>
                    </div>
                  ) : (
                    <>
                      <div className="progress-track"><div className="progress-fill" style={{ width: s.prog + '%', background: hue }} /></div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
                        <span className="t-meta">{s.lessons} lessons</span>
                        <span className="t-meta" style={{ color: hue, fontWeight: 600 }}>{s.prog}%</span>
                      </div>
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
      <TabBar active="subjects" />
    </>
  );
}

Object.assign(window, { ScreenUnlockSubject, ScreenUnlockExam, ScreenSubjectsLocked });
