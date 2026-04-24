// NA-Academy — all screens

// ─── ONBOARDING ─────────────────────────────────────────────
function ScreenOnboarding() {
  const [slide, setSlide] = useState(0);
  const slides = [
    {
      kicker: 'Welcome',
      title: 'A calm place\nto study, ask,\nand grow.',
      body: 'NA-Academy brings your lessons, exams, and tutors into one focused space.',
    },
    {
      kicker: 'Learn',
      title: 'Subjects that\nmove with you.',
      body: 'Bite-sized lessons, progress that sticks, and quick checks to prove you got it.',
    },
    {
      kicker: 'Ask',
      title: 'A tutor in\nyour pocket.',
      body: 'Message your teacher, share a photo of a problem, and get unstuck in minutes.',
    },
  ];
  const s = slides[slide];
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '24px 24px 28px' }}>
      {/* emblem */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
        <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--text-primary)', color: 'var(--bg-canvas)', display: 'grid', placeItems: 'center', fontFamily: 'Fraunces, serif', fontWeight: 600, fontSize: 18 }}>N</div>
        <div className="na-serif" style={{ fontSize: 17, fontWeight: 500 }}>NA·Academy</div>
      </div>
      {/* visual */}
      <div style={{ marginTop: 28, aspectRatio: '1/1', borderRadius: 28, background: 'var(--bg-surface)', boxShadow: 'var(--shadow-card)', position: 'relative', overflow: 'hidden' }}>
        <OnboardingArt i={slide} />
      </div>
      {/* copy */}
      <div style={{ marginTop: 28, flex: 1 }}>
        <div className="t-caption" style={{ color: 'var(--accent)' }}>{s.kicker}</div>
        <div className="t-display na-serif" style={{ marginTop: 10, whiteSpace: 'pre-line' }}>{s.title}</div>
        <div className="t-body muted" style={{ marginTop: 14, maxWidth: 320 }}>{s.body}</div>
      </div>
      {/* dots + actions */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 16 }}>
        {slides.map((_, i) => (
          <div key={i} style={{ height: 4, flex: i === slide ? 2 : 1, borderRadius: 999, background: i === slide ? 'var(--accent)' : 'var(--border-subtle)', transition: 'all 200ms' }} />
        ))}
      </div>
      <button className="btn btn-primary btn-accent btn-block" onClick={() => setSlide((slide + 1) % slides.length)}>
        {slide < slides.length - 1 ? 'Continue' : 'Get started'}
      </button>
      <button className="btn btn-ghost btn-block" style={{ marginTop: 6 }}>I have an account</button>
    </div>
  );
}

function OnboardingArt({ i = 0 }) {
  if (i === 0) return (
    <svg viewBox="0 0 300 300" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
      <defs>
        <pattern id="p1" width="10" height="10" patternUnits="userSpaceOnUse">
          <circle cx="1" cy="1" r="0.8" fill="var(--border-subtle)" />
        </pattern>
      </defs>
      <rect width="300" height="300" fill="url(#p1)" />
      <circle cx="150" cy="150" r="80" fill="var(--accent-soft)" />
      <circle cx="150" cy="150" r="80" fill="none" stroke="var(--accent)" strokeWidth="1.5" />
      <text x="150" y="162" textAnchor="middle" fontFamily="Fraunces, serif" fontSize="48" fontWeight="500" fill="var(--accent-deep)">NA</text>
      <circle cx="230" cy="80" r="14" fill="var(--secondary-soft)" stroke="var(--secondary)" />
      <rect x="60" y="210" width="40" height="40" rx="10" fill="var(--bg-sunken)" stroke="var(--border-subtle)" />
    </svg>
  );
  if (i === 1) return (
    <svg viewBox="0 0 300 300" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
      <rect width="300" height="300" fill="var(--bg-surface)" />
      {[0,1,2,3].map(r => (
        <g key={r}>
          <rect x={40} y={60 + r*44} width={220 - r*20} height={32} rx="10" fill="var(--bg-sunken)" />
          <rect x={48} y={68 + r*44} width={16} height={16} rx="5" fill={r < 2 ? 'var(--accent)' : 'var(--border-subtle)'} />
          <rect x={72} y={72 + r*44} width={100 + r*15} height={8} rx="3" fill="var(--text-primary)" opacity="0.7" />
        </g>
      ))}
      <circle cx="240" cy="240" r="30" fill="var(--accent)" />
      <path d="M226 240 l10 10 l18 -18" stroke="#fff" strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
  return (
    <svg viewBox="0 0 300 300" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
      <rect width="300" height="300" fill="var(--bg-surface)" />
      <g>
        <rect x="40" y="60" width="180" height="54" rx="16" fill="var(--bg-sunken)" />
        <rect x="52" y="74" width="120" height="8" rx="3" fill="var(--text-primary)" opacity="0.8" />
        <rect x="52" y="90" width="80" height="8" rx="3" fill="var(--text-primary)" opacity="0.4" />
        <circle cx="28" cy="86" r="14" fill="var(--accent-soft)" />
      </g>
      <g>
        <rect x="80" y="140" width="180" height="54" rx="16" fill="var(--accent)" />
        <rect x="92" y="154" width="140" height="8" rx="3" fill="#fff" opacity="0.9" />
        <rect x="92" y="170" width="100" height="8" rx="3" fill="#fff" opacity="0.6" />
      </g>
      <g>
        <rect x="40" y="220" width="140" height="40" rx="14" fill="var(--bg-sunken)" />
        <circle cx="54" cy="240" r="3" fill="var(--text-muted)" />
        <circle cx="66" cy="240" r="3" fill="var(--text-muted)" />
        <circle cx="78" cy="240" r="3" fill="var(--text-muted)" />
      </g>
    </svg>
  );
}

// ─── LOGIN ──────────────────────────────────────────────────
function ScreenLogin() {
  return (
    <div style={{ flex: 1, padding: '24px 24px 24px', display: 'flex', flexDirection: 'column' }}>
      <button className="ic-wrap" style={{ border: 'none', cursor: 'pointer', width: 40, height: 40 }}>
        <IconChevronLeft size={20} />
      </button>
      <div style={{ marginTop: 40 }}>
        <div className="t-caption" style={{ color: 'var(--accent)' }}>Sign in</div>
        <div className="t-display na-serif" style={{ marginTop: 10 }}>Welcome back.</div>
        <div className="t-body muted" style={{ marginTop: 10 }}>Pick up right where you left off.</div>
      </div>
      <div style={{ marginTop: 36, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div className="field">
          <label className="field-label">Email</label>
          <input className="input" defaultValue="layla.ahmed@na-academy.org" />
        </div>
        <div className="field">
          <label className="field-label">Password</label>
          <input className="input" type="password" defaultValue="••••••••••" />
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: -4 }}>
          <a className="t-sm" style={{ color: 'var(--accent)', fontWeight: 500 }}>Forgot password?</a>
        </div>
      </div>
      <div style={{ flex: 1 }} />
      <button className="btn btn-primary btn-accent btn-block">Sign in</button>
      <div style={{ textAlign: 'center', marginTop: 16 }} className="t-sm muted">
        New here? <a style={{ color: 'var(--accent)', fontWeight: 500 }}>Create an account</a>
      </div>
    </div>
  );
}

// ─── HOME / TODAY ────────────────────────────────────────────
function ScreenHome() {
  const subjects = [
    { title: 'Calculus II', prog: 68, chip: 'Lesson 12 of 18', color: 'accent' },
    { title: 'Organic Chemistry', prog: 32, chip: 'Lesson 6 of 20', color: 'secondary' },
    { title: 'Modern Arabic Literature', prog: 84, chip: 'Lesson 15 of 18', color: 'accent' },
  ];
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        {/* greeting */}
        <div style={{ padding: '12px 4px 20px', display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
          <div>
            <div className="t-caption muted">Wednesday, April 24</div>
            <div className="t-display na-serif" style={{ marginTop: 6, maxWidth: 280 }}>Good afternoon,<br/>Layla.</div>
          </div>
          <button className="ic-wrap" style={{ border: 'none', background: 'var(--bg-surface)', boxShadow: 'var(--shadow-card)', width: 40, height: 40 }}>
            <IconBell size={18} />
          </button>
        </div>

        {/* streak strip */}
        <div className="card" style={{ display: 'flex', alignItems: 'center', gap: 14, background: 'var(--bg-surface)', marginBottom: 16 }}>
          <div className="ic-wrap ic-wrap-secondary" style={{ width: 42, height: 42 }}><IconFlame size={20} /></div>
          <div style={{ flex: 1 }}>
            <div className="t-body-strong">12-day streak</div>
            <div className="t-meta">Keep it alive — 18 min left today</div>
          </div>
          <Ring value={72} size={42} stroke={4}>
            <span style={{ fontSize: 11, fontWeight: 600 }}>72%</span>
          </Ring>
        </div>

        {/* Continue learning */}
        <div className="section-head">
          <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Continue learning</div>
          <a className="action">See all</a>
        </div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 20 }}>
          <div style={{ display: 'flex', aspectRatio: '16/9' }}>
            <div style={{ flex: 1, background: 'linear-gradient(135deg, var(--accent-soft), var(--bg-sunken))', position: 'relative', display: 'grid', placeItems: 'center' }}>
              <svg width="60%" viewBox="0 0 100 60">
                <path d="M10 50 Q 30 10, 50 30 T 90 20" fill="none" stroke="var(--accent-deep)" strokeWidth="1.5" />
                <text x="50" y="54" fontSize="5" fontFamily="JetBrains Mono" textAnchor="middle" fill="var(--text-muted)">f(x) = sin(x)</text>
              </svg>
              <div style={{ position: 'absolute', bottom: 12, left: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{ width: 32, height: 32, borderRadius: 999, background: 'var(--bg-elevated)', display: 'grid', placeItems: 'center', boxShadow: 'var(--shadow-card)' }}>
                  <IconPlay size={14} />
                </div>
                <span className="t-sm" style={{ fontWeight: 500, background: 'var(--bg-elevated)', padding: '4px 10px', borderRadius: 999, boxShadow: 'var(--shadow-card)' }}>Resume · 4:12</span>
              </div>
            </div>
          </div>
          <div style={{ padding: 14 }}>
            <div className="t-caption muted">Calculus II · Lesson 12</div>
            <div className="t-h1 na-serif" style={{ fontWeight: 500, marginTop: 4 }}>Trigonometric substitution</div>
            <div className="progress-track" style={{ marginTop: 12 }}>
              <div className="progress-fill" style={{ width: '68%' }} />
            </div>
          </div>
        </div>

        {/* Today's exam */}
        <div className="section-head">
          <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Due today</div>
        </div>
        <div className="card" style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 20 }}>
          <div className="ic-wrap ic-wrap-accent" style={{ width: 44, height: 44 }}><IconClipboard size={20} /></div>
          <div style={{ flex: 1 }}>
            <div className="t-body-strong">Midterm · Organic Chemistry</div>
            <div className="t-meta" style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 2 }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><IconClock size={12} />45 min</span>
              <span className="dot" style={{ opacity: 0.4 }} />
              <span>20 questions</span>
            </div>
          </div>
          <button className="btn btn-sm btn-primary btn-accent">Start</button>
        </div>

        {/* Subjects scroller */}
        <div className="section-head">
          <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Your subjects</div>
          <a className="action">All</a>
        </div>
        <div style={{ display: 'flex', gap: 12, overflowX: 'auto', margin: '0 -16px', padding: '4px 16px 8px' }}>
          {subjects.map((s, i) => (
            <div key={i} className="card" style={{ minWidth: 210, flexShrink: 0 }}>
              <div className="chip" style={{
                background: s.color === 'secondary' ? 'var(--secondary-soft)' : 'var(--accent-soft)',
                color: s.color === 'secondary' ? 'var(--secondary)' : 'var(--accent-deep)',
              }}>{s.chip}</div>
              <div className="t-h2 na-serif" style={{ fontWeight: 500, marginTop: 14, minHeight: 52 }}>{s.title}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 16 }}>
                <Ring value={s.prog} size={36} stroke={3.5} color={s.color === 'secondary' ? 'var(--secondary)' : 'var(--accent)'}>
                  <span style={{ fontSize: 9, fontWeight: 600 }}>{s.prog}%</span>
                </Ring>
                <div className="t-meta">Continue</div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <TabBar active="home" />
    </>
  );
}

// ─── SUBJECTS LIST ───────────────────────────────────────────
function ScreenSubjects() {
  const cats = ['All', 'Science', 'Math', 'Languages', 'Arts'];
  const items = [
    { title: 'Calculus II', cat: 'Math', lessons: 18, prog: 68, hue: 'accent' },
    { title: 'Organic Chemistry', cat: 'Science', lessons: 20, prog: 32, hue: 'secondary' },
    { title: 'Modern Arabic Literature', cat: 'Languages', lessons: 18, prog: 84, hue: 'accent' },
    { title: 'Physics · Mechanics', cat: 'Science', lessons: 16, prog: 45, hue: 'accent' },
    { title: 'World History: 1900–now', cat: 'Arts', lessons: 22, prog: 12, hue: 'secondary' },
    { title: 'Linear Algebra', cat: 'Math', lessons: 14, prog: 0, hue: 'accent' },
  ];
  return (
    <>
      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 120px' }}>
        <div style={{ padding: '12px 4px 16px' }}>
          <div className="t-display na-serif">Learn</div>
          <div className="t-body muted" style={{ marginTop: 6 }}>Six subjects in play. Two due this week.</div>
        </div>

        {/* search */}
        <div className="card-sunken" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 14px', marginBottom: 14 }}>
          <IconSearch size={16} color="var(--text-muted)" />
          <input placeholder="Search subjects, lessons, notes" style={{ flex: 1, border: 'none', background: 'transparent', outline: 'none', fontSize: 14, color: 'var(--text-primary)', fontFamily: 'inherit' }} />
        </div>

        {/* categories */}
        <div style={{ display: 'flex', gap: 8, overflowX: 'auto', margin: '0 -16px', padding: '4px 16px 14px' }}>
          {cats.map((c, i) => (
            <div key={c} className="chip" style={{ padding: '8px 14px', fontSize: 13, flexShrink: 0,
              background: i === 0 ? 'var(--text-primary)' : 'var(--bg-surface)',
              color: i === 0 ? 'var(--bg-surface)' : 'var(--text-secondary)',
              boxShadow: i === 0 ? 'none' : 'inset 0 0 0 1px var(--border-subtle)',
            }}>{c}</div>
          ))}
        </div>

        {/* grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {items.map((s, i) => {
            const hue = s.hue === 'secondary' ? 'var(--secondary)' : 'var(--accent)';
            const soft = s.hue === 'secondary' ? 'var(--secondary-soft)' : 'var(--accent-soft)';
            return (
              <div key={i} className="card" style={{ padding: 14 }}>
                <div style={{ height: 60, borderRadius: 12, background: soft, marginBottom: 12, position: 'relative', overflow: 'hidden' }}>
                  <svg viewBox="0 0 100 60" width="100%" height="100%" preserveAspectRatio="none">
                    {i % 2 === 0
                      ? <path d={`M 0 ${40 - i*3} Q 25 ${20 + i*2} 50 ${30 - i} T 100 ${25 + i*2}`} fill="none" stroke={hue} strokeWidth="1" opacity="0.6" />
                      : <g opacity="0.5"><circle cx="30" cy="30" r="18" fill="none" stroke={hue} /><circle cx="65" cy="30" r="12" fill="none" stroke={hue} /></g>}
                  </svg>
                </div>
                <div className="t-caption" style={{ color: hue, marginBottom: 6 }}>{s.cat}</div>
                <div className="t-h2 na-serif" style={{ fontWeight: 500, minHeight: 44 }}>{s.title}</div>
                <div style={{ marginTop: 10 }}>
                  <div className="progress-track"><div className="progress-fill" style={{ width: s.prog + '%', background: hue }} /></div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
                    <span className="t-meta">{s.lessons} lessons</span>
                    <span className="t-meta" style={{ color: hue, fontWeight: 600 }}>{s.prog}%</span>
                  </div>
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

// ─── SUBJECT DETAIL ──────────────────────────────────────────
function ScreenSubjectDetail() {
  const lessons = [
    { n: 1, title: 'What is a limit?', dur: '8 min', state: 'done' },
    { n: 2, title: 'Continuity and discontinuity', dur: '11 min', state: 'done' },
    { n: 3, title: 'Definite integrals, visualized', dur: '14 min', state: 'done' },
    { n: 4, title: 'Fundamental theorem', dur: '16 min', state: 'active' },
    { n: 5, title: 'Substitution — u-sub warm-up', dur: '9 min', state: 'locked' },
    { n: 6, title: 'Integration by parts', dur: '18 min', state: 'locked' },
  ];
  return (
    <>
      <Header back title="Calculus II" right={<button className="ic-wrap" style={{ border: 'none', width: 40, height: 40 }}><IconMore size={18} /></button>} />
      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px 120px' }}>
        {/* hero */}
        <div className="card" style={{ padding: 20, display: 'flex', gap: 16, alignItems: 'center', marginBottom: 16 }}>
          <Ring value={68} size={72} stroke={6}>
            <span style={{ fontSize: 14, fontWeight: 600 }}>68%</span>
          </Ring>
          <div style={{ flex: 1 }}>
            <div className="t-caption" style={{ color: 'var(--accent)' }}>Math · 18 lessons</div>
            <div className="t-h1 na-serif" style={{ fontWeight: 500, marginTop: 4 }}>Integration, from first principles.</div>
          </div>
        </div>

        {/* stats strip */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 20 }}>
          {[['12', 'done'], ['1', 'in progress'], ['5', 'to go']].map(([n, l], i) => (
            <div key={i} className="card-flat" style={{ textAlign: 'center', padding: '12px 8px' }}>
              <div className="t-h1 na-serif" style={{ fontWeight: 500 }}>{n}</div>
              <div className="t-meta" style={{ marginTop: 2 }}>{l}</div>
            </div>
          ))}
        </div>

        <div className="section-head">
          <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Lessons</div>
          <a className="action">Syllabus</a>
        </div>

        <div className="row-group">
          {lessons.map((l, i) => {
            const iconBg = l.state === 'done' ? 'var(--accent)' : l.state === 'active' ? 'var(--bg-sunken)' : 'var(--bg-sunken)';
            const iconColor = l.state === 'done' ? '#fff' : l.state === 'active' ? 'var(--accent-deep)' : 'var(--text-muted)';
            return (
              <div key={i} className="row">
                <div style={{ width: 32, height: 32, borderRadius: 999, background: iconBg, color: iconColor, display: 'grid', placeItems: 'center', fontWeight: 600, fontSize: 13 }}>
                  {l.state === 'done' ? <IconCheck size={14} /> : l.state === 'locked' ? <IconLock size={13} /> : l.n}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="t-body-strong" style={{ color: l.state === 'locked' ? 'var(--text-muted)' : 'var(--text-primary)' }}>{l.title}</div>
                  <div className="t-meta">{l.dur}</div>
                </div>
                {l.state === 'active' && <span className="chip chip-accent">Continue</span>}
                <IconChevronRight size={16} color="var(--text-muted)" />
              </div>
            );
          })}
        </div>
      </div>
    </>
  );
}

Object.assign(window, { ScreenOnboarding, ScreenLogin, ScreenHome, ScreenSubjects, ScreenSubjectDetail });
