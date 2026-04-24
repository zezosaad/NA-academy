// NA-Academy phone screens (R = React, all global)
const { useState, useEffect, useRef } = React;

// ─────────────────────────────────────────────────────────────
// Phone wrapper — simplified iOS-style frame (no nav bar clutter)
// ─────────────────────────────────────────────────────────────
function Phone({ children, dark = false, label, bg }) {
  return (
    <div className={dark ? 'na na-dark' : 'na'} style={{
      width: 390, height: 844, borderRadius: 48, overflow: 'hidden',
      position: 'relative', background: bg || 'var(--bg-canvas)',
      boxShadow: '0 40px 80px rgba(31,28,22,0.18), 0 0 0 10px #141310, 0 0 0 11px #2a2824',
    }}>
      {/* status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 54, zIndex: 30,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '16px 28px 0', fontSize: 15, fontWeight: 600,
        color: 'var(--text-primary)',
      }}>
        <span>9:41</span>
        <span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <svg width="17" height="11" viewBox="0 0 17 11"><path d="M1 8h2v3H1zM5 6h2v5H5zM9 4h2v7H9zM13 1h2v10h-2z" fill="currentColor"/></svg>
          <svg width="15" height="11" viewBox="0 0 15 11"><path d="M7.5 2.5a7 7 0 0 1 5 2.1l-1.2 1.2A5.3 5.3 0 0 0 7.5 4.3a5.3 5.3 0 0 0-3.8 1.5L2.5 4.6a7 7 0 0 1 5-2.1zm0 3a4 4 0 0 1 2.8 1.2L9.1 7.9a2.3 2.3 0 0 0-1.6-.6 2.3 2.3 0 0 0-1.6.6L4.7 6.7a4 4 0 0 1 2.8-1.2zm0 3a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3z" fill="currentColor"/></svg>
          <svg width="24" height="11" viewBox="0 0 24 11"><rect x="0.5" y="0.5" width="21" height="10" rx="2" fill="none" stroke="currentColor" opacity="0.5"/><rect x="2" y="2" width="16" height="7" rx="1" fill="currentColor"/><rect x="22" y="3.5" width="1.5" height="4" rx="0.5" fill="currentColor" opacity="0.5"/></svg>
        </span>
      </div>
      {/* dynamic island */}
      <div style={{
        position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
        width: 120, height: 35, borderRadius: 22, background: '#000', zIndex: 40,
      }} />
      {/* content */}
      <div style={{ position: 'absolute', inset: 0, paddingTop: 54, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
      {/* home indicator */}
      <div style={{
        position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
        width: 134, height: 5, borderRadius: 3,
        background: 'var(--text-primary)', opacity: 0.35, zIndex: 50,
      }} />
    </div>
  );
}

// Tab bar — floating pill
function TabBar({ active = 'home', onChange = () => {} }) {
  const tabs = [
    { id: 'home', icon: IconHome, label: 'Today' },
    { id: 'subjects', icon: IconBook, label: 'Learn' },
    { id: 'exams', icon: IconClipboard, label: 'Exams' },
    { id: 'chat', icon: IconChat, label: 'Chat' },
    { id: 'profile', icon: IconUser, label: 'You' },
  ];
  return (
    <div className="tabbar">
      {tabs.map(t => {
        const Ico = t.icon;
        const on = active === t.id;
        return (
          <div key={t.id} className={`tab ${on ? 'active' : ''}`} onClick={() => onChange(t.id)}>
            <Ico size={20} stroke={on ? 2 : 1.6} />
            {on && <span style={{ fontWeight: 600 }}>{t.label}</span>}
          </div>
        );
      })}
    </div>
  );
}

// Screen header
function Header({ title, back, right, subtitle }) {
  return (
    <div style={{ padding: '8px 16px 12px', display: 'flex', alignItems: 'center', gap: 12, minHeight: 48 }}>
      {back && (
        <button className="ic-wrap" style={{ border: 'none', cursor: 'pointer' }} aria-label="Back">
          <IconChevronLeft size={20} />
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        {title && <div className="t-h2" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>}
        {subtitle && <div className="t-meta">{subtitle}</div>}
      </div>
      {right}
    </div>
  );
}

// Progress ring (SVG)
function Ring({ value = 0, size = 44, stroke = 4, color = 'var(--accent)', trackColor = 'var(--bg-sunken)', children }) {
  const r = (size - stroke) / 2;
  const C = 2 * Math.PI * r;
  const off = C * (1 - value / 100);
  return (
    <div style={{ position: 'relative', width: size, height: size, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={trackColor} strokeWidth={stroke} />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={stroke}
          strokeDasharray={C} strokeDashoffset={off} strokeLinecap="round"
          style={{ transition: 'stroke-dashoffset 400ms' }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: size * 0.28, fontWeight: 600 }}>
        {children ?? `${value}%`}
      </div>
    </div>
  );
}

Object.assign(window, { Phone, TabBar, Header, Ring });
