export type DamageSeverity = 'none' | 'minor' | 'major';

type ZoneDef = {
  name: string;
  rect: { left: number; top: number; width: number; height: number };
  dot: { x: number; y: number };
};

const VIEWBOX = { width: 100, height: 190 };

export const vehicleDamageZones: ZoneDef[] = [
  { name: 'Front Bumper', rect: { left: 10, top: 10, width: 78, height: 22 }, dot: { x: 49, y: 21 } },
  { name: 'Hood', rect: { left: 14, top: 20, width: 70, height: 34 }, dot: { x: 49, y: 37 } },
  { name: 'Front Left Fender', rect: { left: 10, top: 38, width: 16, height: 30 }, dot: { x: 18, y: 53 } },
  { name: 'Front Right Fender', rect: { left: 72, top: 38, width: 16, height: 30 }, dot: { x: 80, y: 53 } },
  { name: 'Left Door', rect: { left: 10, top: 66, width: 16, height: 50 }, dot: { x: 18, y: 91 } },
  { name: 'Right Door', rect: { left: 72, top: 66, width: 16, height: 50 }, dot: { x: 80, y: 91 } },
  { name: 'Rear Left Fender', rect: { left: 10, top: 114, width: 16, height: 28 }, dot: { x: 18, y: 128 } },
  { name: 'Rear Right Fender', rect: { left: 72, top: 114, width: 16, height: 28 }, dot: { x: 80, y: 128 } },
  { name: 'Boot/Trunk', rect: { left: 14, top: 126, width: 70, height: 34 }, dot: { x: 49, y: 143 } },
  { name: 'Rear Bumper', rect: { left: 10, top: 156, width: 78, height: 22 }, dot: { x: 49, y: 167 } },
  { name: 'Roof', rect: { left: 22, top: 66, width: 54, height: 48 }, dot: { x: 49, y: 90 } },
];

export function cycleDamage(current: DamageSeverity): DamageSeverity {
  if (current === 'none') return 'minor';
  if (current === 'minor') return 'major';
  return 'none';
}

export function severityToApi(severity: DamageSeverity): string {
  return severity === 'major' ? 'severe' : 'minor';
}

export function severityFromApi(value: string | undefined): DamageSeverity {
  if (value === 'severe' || value === 'major') return 'major';
  if (value === 'minor' || value === 'moderate') return 'minor';
  return 'none';
}

export function VehicleDamageMap(props: {
  damageZones: Record<string, DamageSeverity>;
  onZoneTap: (zone: string) => void;
  onClearAll?: () => void;
}) {
  const marked = Object.entries(props.damageZones).filter(([, severity]) => severity !== 'none');

  return (
    <div className="damage-map">
      <div className="damage-map__header">
        <h4>Damage map</h4>
        {props.onClearAll && marked.length > 0 ? (
          <button type="button" className="text-link-action" onClick={props.onClearAll}>
            Clear all
          </button>
        ) : null}
      </div>
      <div className="damage-map__canvas">
        <svg viewBox={`0 0 ${VIEWBOX.width} ${VIEWBOX.height}`} role="img" aria-label="Vehicle damage map">
          <rect x="30" y="32" width="40" height="126" rx="18" fill="#1e293b" stroke="#334155" strokeWidth="1.5" />
          <rect x="22" y="18" width="56" height="36" rx="10" fill="#1e293b" stroke="#334155" strokeWidth="1.5" />
          <rect x="22" y="136" width="56" height="36" rx="10" fill="#1e293b" stroke="#334155" strokeWidth="1.5" />
          <circle cx="26" cy="52" r="7" fill="#0f172a" stroke="#475569" />
          <circle cx="74" cy="52" r="7" fill="#0f172a" stroke="#475569" />
          <circle cx="26" cy="138" r="7" fill="#0f172a" stroke="#475569" />
          <circle cx="74" cy="138" r="7" fill="#0f172a" stroke="#475569" />
          {vehicleDamageZones.map((zone) => {
            const severity = props.damageZones[zone.name] ?? 'none';
            const fill =
              severity === 'major' ? 'rgba(239,68,68,0.35)' : severity === 'minor' ? 'rgba(249,115,22,0.35)' : 'transparent';
            return (
              <rect
                key={zone.name}
                x={zone.rect.left}
                y={zone.rect.top}
                width={zone.rect.width}
                height={zone.rect.height}
                fill={fill}
                stroke="transparent"
                style={{ cursor: 'pointer' }}
                onClick={() => props.onZoneTap(zone.name)}
              >
                <title>{zone.name}</title>
              </rect>
            );
          })}
          {vehicleDamageZones.map((zone) => {
            const severity = props.damageZones[zone.name] ?? 'none';
            if (severity === 'none') return null;
            const color = severity === 'major' ? '#ef4444' : '#f97316';
            return <circle key={`dot-${zone.name}`} cx={zone.dot.x} cy={zone.dot.y} r="4" fill={color} stroke="#fff" strokeWidth="1" />;
          })}
        </svg>
      </div>
      <div className="damage-map__legend">
        <span><i className="damage-dot damage-dot--minor" /> Minor</span>
        <span><i className="damage-dot damage-dot--major" /> Major</span>
        <span className="muted">Tap zones to cycle: none → minor → major</span>
      </div>
      {marked.length > 0 ? (
        <ul className="damage-map__list">
          {marked.map(([name, severity]) => (
            <li key={name} className={severity === 'major' ? 'damage-major' : 'damage-minor'}>
              {name}
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
