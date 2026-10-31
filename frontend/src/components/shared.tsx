'use client';
import { ArrowUpRight, Check, Clock3, Plus, Search, SlidersHorizontal } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { actionById } from '@/lib/spec';
import { actionAvailability } from '@/mocks/engine';
import { useDemo } from '@/store/demo';
import type { Patient } from '@/lib/types';
import type { CommandTarget } from '@/mocks/engine';

export function PersonAvatar({ patient, size = '' }: { patient: Pick<Patient, 'avatar' | 'color'>; size?: string }) { return <span className={`person-avatar ${patient.color} ${size}`}>{patient.avatar}</span>; }
export function Status({ value }: { value: string }) {
  const kind = /cancel|rechaz|revoc|retir|suspend|no realizada|error/i.test(value) ? 'danger' : /firm|finaliz|complet|confirm|vigente|disponible|public|realizada|pagad|acept/i.test(value) ? 'success' : /atención|curso|llamada|activa/i.test(value) ? 'active' : 'pending';
  return <Badge variant="secondary" className={`status-badge ${kind}`}><span className="status-dot" />{value}</Badge>;
}
export function ActionButton({ id, target, children, variant = 'outline', className = '', icon = false }: { id: string; target?: CommandTarget; children?: React.ReactNode; variant?: 'default' | 'outline' | 'ghost' | 'secondary' | 'destructive'; className?: string; icon?: boolean }) {
  const { data, context, open } = useDemo(); const action = actionById[id];
  if (!action) return null;
  const reason = actionAvailability(id, data, context);
  return <span className="action-wrap" title={reason || action.label}><Button data-action={id} variant={variant} className={className} disabled={!!reason} onClick={() => open({ kind: 'action', actionId: id, target })}>{icon && <Plus size={15} />}{children || action.label}</Button></span>;
}
export function EmptyState({ title = 'Todavía no hay registros', description = 'Crea el primer registro para comenzar este recorrido.', action }: { title?: string; description?: string; action?: React.ReactNode }) {
  return <div className="empty-state"><div className="empty-icon"><Search size={25} strokeWidth={1.3} /></div><h3>{title}</h3><p>{description}</p>{action}</div>;
}
export function SectionHeading({ eyebrow, title, description, actions }: { eyebrow?: string; title: string; description?: string; actions?: React.ReactNode }) {
  return <div className="page-heading"><div>{eyebrow && <p className="eyebrow">{eyebrow}</p>}<h1>{title}</h1>{description && <p className="page-description">{description}</p>}</div><div className="heading-actions">{actions}</div></div>;
}
export function SearchField({ value, onChange, placeholder = 'Buscar…' }: { value: string; onChange: (v: string) => void; placeholder?: string }) { return <div className="search-field"><Search size={16} /><Input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} /></div>; }
export function Metric({ label, value, detail, icon, tone = '' }: { label: string; value: string | number; detail: string; icon: React.ReactNode; tone?: string }) {
  return <div className={`metric ${tone}`}><div className="metric-top"><span>{label}</span><span className="metric-icon">{icon}</span></div><strong>{value}</strong><p><span className="metric-small-dot" />{detail}</p></div>;
}
export const CheckIcon = Check;
export const ClockIcon = Clock3;
export const ArrowIcon = ArrowUpRight;
export const FiltersIcon = SlidersHorizontal;
