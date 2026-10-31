import type { FormValues } from './types';
export function inDateRange(date: string, values: FormValues = {}) {
  return (!values.fechaDesde || date >= String(values.fechaDesde)) && (!values.fechaHasta || date <= String(values.fechaHasta));
}
export const queryFrom = (values: FormValues = {}) => String(values.busqueda || values.nombre || values.identificacion || '');
