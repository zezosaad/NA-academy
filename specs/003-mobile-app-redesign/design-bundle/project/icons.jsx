// Minimal line icons (lucide-style) — original drawings
const Ic = ({ children, size = 20, stroke = 1.75, color = 'currentColor', style }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color}
    strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={style}>
    {children}
  </svg>
);

const IconHome = (p) => <Ic {...p}><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1z"/></Ic>;
const IconBook = (p) => <Ic {...p}><path d="M4 4a2 2 0 0 1 2-2h13v18H6a2 2 0 0 0-2 2z"/><path d="M4 20a2 2 0 0 1 2-2h13"/></Ic>;
const IconClipboard = (p) => <Ic {...p}><rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4V3a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1"/><path d="M9 11h6M9 15h4"/></Ic>;
const IconChat = (p) => <Ic {...p}><path d="M21 12a8 8 0 0 1-11.3 7.3L4 20.5l1.3-5A8 8 0 1 1 21 12Z"/></Ic>;
const IconUser = (p) => <Ic {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></Ic>;
const IconSearch = (p) => <Ic {...p}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></Ic>;
const IconPlus = (p) => <Ic {...p}><path d="M12 5v14M5 12h14"/></Ic>;
const IconSend = (p) => <Ic {...p}><path d="M4 12 20 4l-5 16-3.5-7z"/></Ic>;
const IconStop = (p) => <Ic {...p}><rect x="6" y="6" width="12" height="12" rx="2"/></Ic>;
const IconPlay = (p) => <Ic {...p}><path d="M7 4v16l14-8z"/></Ic>;
const IconClock = (p) => <Ic {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></Ic>;
const IconCheck = (p) => <Ic {...p}><path d="m5 12 5 5L20 7"/></Ic>;
const IconChevronLeft = (p) => <Ic {...p}><path d="m15 5-7 7 7 7"/></Ic>;
const IconChevronRight = (p) => <Ic {...p}><path d="m9 5 7 7-7 7"/></Ic>;
const IconChevronDown = (p) => <Ic {...p}><path d="m5 9 7 7 7-7"/></Ic>;
const IconBell = (p) => <Ic {...p}><path d="M6 8a6 6 0 1 1 12 0c0 6 2 8 2 8H4s2-2 2-8"/><path d="M10 20a2 2 0 0 0 4 0"/></Ic>;
const IconSettings = (p) => <Ic {...p}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></Ic>;
const IconFlame = (p) => <Ic {...p}><path d="M12 2s4 5 4 9a4 4 0 1 1-8 0c0-2 1-3 1-3s-3-2-3-5c0 6 6 5 6 5s0-3 0-6Z"/></Ic>;
const IconTrophy = (p) => <Ic {...p}><path d="M6 4h12v4a6 6 0 0 1-12 0z"/><path d="M4 4h2v3a2 2 0 0 1-2 2zM18 4h2v5a2 2 0 0 1-2-2z"/><path d="M10 14h4v4h-4zM8 22h8"/></Ic>;
const IconSparkle = (p) => <Ic {...p}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5 18 18M6 18l2.5-2.5M15.5 8.5 18 6"/></Ic>;
const IconLock = (p) => <Ic {...p}><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 1 1 8 0v4"/></Ic>;
const IconMenu = (p) => <Ic {...p}><path d="M4 6h16M4 12h16M4 18h16"/></Ic>;
const IconMore = (p) => <Ic {...p}><circle cx="5" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="19" cy="12" r="1.3"/></Ic>;
const IconMoon = (p) => <Ic {...p}><path d="M20 14A8 8 0 1 1 10 4a7 7 0 0 0 10 10Z"/></Ic>;
const IconGlobe = (p) => <Ic {...p}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></Ic>;
const IconLogout = (p) => <Ic {...p}><path d="M10 4H5a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h5"/><path d="m16 8 4 4-4 4M8 12h12"/></Ic>;
const IconPaperclip = (p) => <Ic {...p}><path d="m21 10-9 9a5 5 0 1 1-7-7l9-9a3.5 3.5 0 1 1 5 5l-8.5 8.5a2 2 0 1 1-3-3l7-7"/></Ic>;
const IconImage = (p) => <Ic {...p}><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 17-5-5-9 9"/></Ic>;
const IconBookmark = (p) => <Ic {...p}><path d="M6 3h12v18l-6-4-6 4z"/></Ic>;
const IconMic = (p) => <Ic {...p}><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3M9 21h6"/></Ic>;

Object.assign(window, {
  Ic, IconHome, IconBook, IconClipboard, IconChat, IconUser, IconSearch,
  IconPlus, IconSend, IconStop, IconPlay, IconClock, IconCheck,
  IconChevronLeft, IconChevronRight, IconChevronDown, IconBell,
  IconSettings, IconFlame, IconTrophy, IconSparkle, IconLock,
  IconMenu, IconMore, IconMoon, IconGlobe, IconLogout, IconPaperclip,
  IconImage, IconBookmark, IconMic,
});
