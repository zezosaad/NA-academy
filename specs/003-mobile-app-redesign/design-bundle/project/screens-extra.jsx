// NA-Academy — splash, register, code-states

// ─── SPLASH ──────────────────────────────────────────────────
function ScreenSplash() {
  return (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      background: 'var(--bg-canvas)', position: 'relative', overflow: 'hidden', padding: 24
    }}>
      {/* soft radial */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(circle at 50% 42%, var(--accent-soft) 0%, transparent 55%)'
      }} />
      {/* mono dotted frame */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.35 }}>
        <defs>
          <pattern id="spdots" width="14" height="14" patternUnits="userSpaceOnUse">
            <circle cx="1" cy="1" r="0.9" fill="var(--border-strong)" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#spdots)" />
      </svg>

      {/* logo */}
      <div style={{ position: 'relative', zIndex: 2, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22 }}>
        <div style={{
          width: 108, height: 108, borderRadius: 32,
          background: 'var(--text-primary)', color: 'var(--bg-canvas)',
          display: 'grid', placeItems: 'center',
          boxShadow: '0 20px 40px rgba(31,28,22,0.18), 0 0 0 8px rgba(255,255,255,0.55)',
          fontFamily: 'Fraunces, serif', fontSize: 52, fontWeight: 500, letterSpacing: '-0.03em'
        }}>N</div>
        <div style={{ textAlign: 'center' }}>
          <div className="na-serif" style={{ fontSize: 32, fontWeight: 500, letterSpacing: '-0.02em' }}>NA·Academy</div>
          <div className="t-caption" style={{ color: 'var(--accent)', marginTop: 8 }}>Learn · Ask · Grow</div>
        </div>
      </div>

      {/* loader */}
      <div style={{ position: 'absolute', bottom: 72, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, zIndex: 2 }}>
        <div style={{ width: 88, height: 3, borderRadius: 999, background: 'var(--border-subtle)', overflow: 'hidden', position: 'relative' }}>
          <div style={{
            position: 'absolute', top: 0, bottom: 0, width: '40%', background: 'var(--accent)',
            borderRadius: 999, animation: 'splash-bar 1.4s ease-in-out infinite'
          }} />
        </div>
        <div className="t-meta" style={{ color: 'var(--text-secondary)' }}>Preparing your study space…</div>
      </div>

      <style>{`
        @keyframes splash-bar {
          0% { left: -40%; }
          100% { left: 100%; }
        }
      `}</style>
    </div>);

}

// ─── REGISTER ────────────────────────────────────────────────
function ScreenRegister() {
  return (
    <div style={{ flex: 1, overflow: 'auto', padding: '24px 24px 28px', display: 'flex', flexDirection: 'column' }}>
      <button className="ic-wrap" style={{ border: 'none', cursor: 'pointer', width: 40, height: 40 }}>
        <IconChevronLeft size={20} />
      </button>

      <div style={{ marginTop: 24 }}>
        <div className="t-caption" style={{ color: 'var(--accent)' }}>Sign up</div>
        <div className="t-display na-serif" style={{ marginTop: 10 }}>Create your<br />account.</div>
        <div className="t-body muted" style={{ marginTop: 10 }}>A quiet place for lessons, exams, and your tutors.</div>
      </div>

      {/* avatar pick */}
      <div style={{ marginTop: 24, display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ position: 'relative' }}>
          <div className="avatar" style={{ width: 56, height: 56, fontSize: 20, background: 'var(--accent-soft)', color: 'var(--accent-deep)' }}>L</div>
          <div style={{ position: 'absolute', bottom: -2, right: -2, width: 22, height: 22, borderRadius: 999, background: 'var(--accent)', color: '#fff', display: 'grid', placeItems: 'center', border: '2px solid var(--bg-canvas)' }}>
            <IconImage size={11} />
          </div>
        </div>
        <div style={{ flex: 1 }}>
          <div className="t-body-strong" style={{ fontSize: 14 }}>Profile photo</div>
          <div className="t-meta" style={{ marginTop: 2 }}>Optional — you can add one later.</div>
        </div>
      </div>

      {/* form */}
      <div style={{ marginTop: 22, display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div className="field">
          <label className="field-label">Full name</label>
          <input className="input" defaultValue="Layla Ahmed" />
        </div>
        <div className="field">
          <label className="field-label">Email</label>
          <input className="input" defaultValue="layla.ahmed@example.com" />
        </div>
        <div className="field">
          <label className="field-label">Password</label>
          <div style={{ position: 'relative' }}>
            <input className="input" type="password" defaultValue="••••••••••" style={{ width: '100%', boxSizing: 'border-box', paddingRight: 52 }} />
            <span className="t-sm" style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', color: 'var(--accent)', fontWeight: 500 }}>Show</span>
          </div>
          {/* strength meter */}
          <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
            {[0, 1, 2, 3].map((i) =>
            <div key={i} style={{ flex: 1, height: 3, borderRadius: 999, background: i < 3 ? 'var(--accent)' : 'var(--border-subtle)' }} />
            )}
          </div>
          <div className="t-meta" style={{ marginTop: 4 }}>Strong password · 11 characters</div>
        </div>
        {/* terms */}
        <label style={{ display: 'flex', gap: 10, alignItems: 'flex-start', marginTop: 4, cursor: 'pointer' }}>
          <div style={{ width: 20, height: 20, borderRadius: 6, background: 'var(--accent)', display: 'grid', placeItems: 'center', flexShrink: 0, marginTop: 1 }}>
            <IconCheck size={12} color="#fff" />
          </div>
          <div className="t-sm muted">
            I agree to the <a style={{ color: 'var(--accent)', fontWeight: 500 }}>Terms</a> and <a style={{ color: 'var(--accent)', fontWeight: 500 }}>Privacy Policy</a>.
          </div>
        </label>
      </div>

      <button className="btn btn-primary btn-accent btn-block" style={{ marginTop: 22 }}>Create account</button>
      <div style={{ textAlign: 'center', marginTop: 14 }} className="t-sm muted">
        Already have one? <a style={{ color: 'var(--accent)', fontWeight: 500 }}>Sign in</a>
      </div>
    </div>);

}

// ─── CODE UNLOCKING (loading after valid code) ───────────────
function ScreenCodeUnlocking() {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 40, textAlign: 'center' }}>
      <div style={{ position: 'relative', width: 140, height: 140 }}>
        <svg width="140" height="140" viewBox="0 0 140 140" style={{ transform: 'rotate(-90deg)' }}>
          <circle cx="70" cy="70" r="62" fill="none" stroke="var(--bg-sunken)" strokeWidth="6" />
          <circle cx="70" cy="70" r="62" fill="none" stroke="var(--accent)" strokeWidth="6"
          strokeDasharray="389" strokeDashoffset="100" strokeLinecap="round"
          style={{ animation: 'spin 1.4s linear infinite' }} />
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center' }}>
          <div style={{ width: 64, height: 64, borderRadius: 20, background: 'var(--accent)', color: '#fff', display: 'grid', placeItems: 'center' }}>
            <IconCheck size={28} />
          </div>
        </div>
      </div>
      <div className="t-title na-serif" style={{ marginTop: 28 }}>Code accepted.</div>
      <div className="t-body muted" style={{ marginTop: 8, maxWidth: 280 }}>Unlocking <b style={{ color: 'var(--text-primary)', fontWeight: 600 }}>Organic Chemistry</b> — pulling lessons and syllabus…</div>

      <div style={{ marginTop: 32, display: 'flex', flexDirection: 'column', gap: 8, alignSelf: 'stretch' }}>
        {[['Verifying code', true], ['Linking to teacher', true], ['Downloading lesson index', false]].map(([l, done], i) =>
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 14px', background: 'var(--bg-surface)', borderRadius: 12, boxShadow: 'var(--shadow-card)' }}>
            <div style={{ width: 18, height: 18, borderRadius: 999, background: done ? 'var(--success)' : 'var(--bg-sunken)', color: '#fff', display: 'grid', placeItems: 'center' }}>
              {done ? <IconCheck size={10} /> : <div style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--text-muted)' }} />}
            </div>
            <div className="t-sm" style={{ textAlign: 'left', color: done ? 'var(--text-primary)' : 'var(--text-muted)' }}>{l}</div>
          </div>
        )}
      </div>

      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>);

}

// ─── CODE EXPIRED / ALREADY USED ─────────────────────────────
function ScreenCodeBad({ variant = 'expired' }) {
  const isExpired = variant === 'expired';
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '24px 24px 28px' }}>
      <button className="ic-wrap" style={{ border: 'none', cursor: 'pointer', width: 40, height: 40 }}>
        <IconChevronLeft size={20} />
      </button>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', textAlign: 'center' }}>
        <div style={{ width: 88, height: 88, borderRadius: 28, background: 'var(--danger-soft)', color: 'var(--danger)', display: 'grid', placeItems: 'center' }}>
          {isExpired ? <IconClock size={36} /> : <IconLock size={34} />}
        </div>
        <div className="t-title na-serif" style={{ marginTop: 22 }}>
          {isExpired ? 'This code has expired.' : 'This code was already used.'}
        </div>
        <div className="t-body muted" style={{ marginTop: 10, maxWidth: 300 }}>
          {isExpired ?
          'Exam codes are only valid during the session window. Ask the proctor for a refreshed code.' :
          'Each access code can only be redeemed once. If this is unexpected, message your teacher.'}
        </div>

        <div className="card" style={{ marginTop: 24, textAlign: 'left', alignSelf: 'stretch' }}>
          <div className="t-caption">Code entered</div>
          <div className="na-mono" style={{ fontSize: 20, letterSpacing: '0.18em', color: 'var(--text-primary)', marginTop: 6 }}>
            EXM-7241
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 12, alignItems: 'center' }}>
            <span className="chip" style={{ background: 'var(--danger-soft)', color: 'var(--danger)' }}>
              {isExpired ? 'Expired 14:32' : 'Used 2h ago'}
            </span>
            <span className="t-meta">Midterm · Organic Chem</span>
          </div>
        </div>
      </div>

      <button className="btn btn-primary btn-accent btn-block">Try a different code</button>
      <button className="btn btn-ghost btn-block" style={{ marginTop: 6 }}>Message teacher</button>
    </div>);

}

// ─── CODE ENTRY AS MODAL (bottom sheet) ──────────────────────
function ScreenCodeModal() {
  const [code, setCode] = useState(['N', 'A', '2', '4', '', '']);
  return (
    <div style={{ flex: 1, position: 'relative', background: 'transparent' }}>
      {/* dimmed background — reuse subjects-locked content as visual */}
      <div style={{ position: 'absolute', inset: 0, background: 'var(--bg-canvas)' }}>
        <div style={{ filter: 'blur(2px)', opacity: 0.6, pointerEvents: 'none' }}>
          {/* lightweight backdrop mock — a few cards */}
          <div style={{ padding: '40px 16px' }}>
            <div className="t-display na-serif" style={{ opacity: 0.4 }}>Learn</div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 16 }}>
              {[0, 1, 2, 3].map((i) =>
              <div key={i} className="card" style={{ height: 160, opacity: 0.6 }} />
              )}
            </div>
          </div>
        </div>
      </div>
      {/* scrim */}
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(31,28,22,0.38)' }} />

      {/* sheet */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: 'var(--bg-surface)',
        borderRadius: '24px 24px 0 0',
        padding: '14px 24px 34px',
        boxShadow: '0 -16px 40px rgba(31,28,22,0.18)'
      }}>
        <div style={{ width: 42, height: 4, borderRadius: 999, background: 'var(--border-strong)', margin: '0 auto 18px' }} />

        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="ic-wrap ic-wrap-accent" style={{ width: 40, height: 40 }}><IconLock size={18} /></div>
          <div style={{ flex: 1 }}>
            <div className="t-h2 na-serif" style={{ fontWeight: 500 }}>Unlock subject</div>
            <div className="t-meta">Enter the 6-character code from your teacher.</div>
          </div>
        </div>

        <div style={{ marginTop: 20, display: 'flex', gap: 8, justifyContent: 'space-between' }}>
          {code.map((c, i) =>
          <div key={i} style={{
            width: 44, height: 56, borderRadius: 14,
            border: `1.5px solid ${c ? 'var(--accent)' : 'var(--border-subtle)'}`,
            background: 'var(--bg-canvas)',
            display: 'grid', placeItems: 'center',
            fontFamily: 'Fraunces, serif', fontSize: 24, fontWeight: 500,
            position: 'relative'
          }}>
              {c || i === 4 && <span className="cursor" style={{ height: 22 }} />}
            </div>
          )}
        </div>
        <div className="t-meta" style={{ marginTop: 10, textAlign: 'center' }}>Letters and numbers · not case-sensitive.</div>

        <button className="btn btn-primary btn-accent btn-block" style={{ marginTop: 22 }}>Unlock</button>
        <button className="btn btn-ghost btn-block" style={{ marginTop: 4 }}>Cancel</button>
      </div>
    </div>);

}

Object.assign(window, {
  ScreenSplash, ScreenRegister, ScreenCodeUnlocking, ScreenCodeBad, ScreenCodeModal
});