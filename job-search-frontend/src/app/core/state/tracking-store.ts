import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, map, of, tap } from 'rxjs';
import { ApplicationsApi, SaveApplicationParams } from '../api/applications-api';
import { TrackingApi } from '../api/tracking-api';
import { ManualJoeStatus, TrackingChanges, TrackingEntry } from '../models';
import { CatalogStore, LoadStatus } from './catalog-store';
import { describeError } from '../errors';

// The tracking fields a person edits on the Tracking page.
const EDITABLE_FIELDS = [
  'applied',
  'date_applied',
  'response_received',
  'follow_up_needed',
  'interview_date',
  'notes',
  'next_follow_up_date',
] as const satisfies readonly (keyof TrackingEntry)[];

// A cleared text or date input ('') means the same as a saved null.
function sameValue(a: unknown, b: unknown): boolean {
  return (a ?? '') === (b ?? '');
}

// Local-state-first store for the Tracking page. Rows are fetched once on app
// load. Edits change only the working copy; pending changes are worked out by
// comparing it with a snapshot of what the database holds, so an edit that's
// put back to its saved value is no change at all. Saves send only real
// differences, and the server's reply becomes the new snapshot. Unsaved edits
// survive page changes.
@Injectable({ providedIn: 'root' })
export class TrackingStore {
  private api = inject(TrackingApi);
  private applicationsApi = inject(ApplicationsApi);
  private catalog = inject(CatalogStore);

  // Working copy: what the page shows and edits.
  readonly entries = signal<TrackingEntry[]>([]);
  // Snapshot of each row as last loaded from or saved to the database.
  private readonly saved = signal<Map<number, TrackingEntry>>(new Map());
  // Unsaved mark-as-dead toggles, by tracking row id (the value lives on the
  // row's job, so it's compared with the job's saved joe_status instead).
  private readonly joeToggles = signal<Map<number, ManualJoeStatus>>(new Map());

  readonly status = signal<LoadStatus>('idle');
  readonly error = signal<string | null>(null);

  // Pending changes per row: fields that differ from the snapshot, plus any toggle.
  readonly changes = computed(() => {
    const saved = this.saved();
    const toggles = this.joeToggles();
    const result = new Map<number, TrackingChanges>();
    for (const entry of this.entries()) {
      const base = saved.get(entry.id);
      const diff: Record<string, unknown> = {};
      if (base) {
        for (const field of EDITABLE_FIELDS) {
          if (!sameValue(entry[field], base[field])) diff[field] = entry[field];
        }
      }
      const joeStatus = toggles.get(entry.id);
      if (joeStatus !== undefined) diff['joe_status'] = joeStatus;
      if (Object.keys(diff).length > 0) result.set(entry.id, diff as TrackingChanges);
    }
    return result;
  });

  readonly hasChanges = computed(() => this.changes().size > 0);

  // Same once-only rules as CatalogStore.load().
  load(): void {
    if (this.status() === 'loading' || this.status() === 'loaded') return;
    this.status.set('loading');
    this.error.set(null);

    this.api.all().subscribe({
      next: (rows) => {
        this.entries.set(rows);
        this.saved.set(new Map(rows.map((row) => [row.id, row])));
        this.joeToggles.set(new Map());
        this.status.set('loaded');
      },
      error: (err) => {
        this.error.set(describeError(err, "Couldn't load your tracked applications"));
        this.status.set('error');
      },
    });
  }

  retry(): void {
    if (this.status() === 'error') this.status.set('idle');
    this.load();
  }

  // --- local edits (no network) ---

  updateField<K extends keyof TrackingEntry>(id: number, field: K, value: TrackingEntry[K]): void {
    this.entries.update((list) =>
      list.map((entry) => (entry.id === id ? { ...entry, [field]: value } : entry)),
    );
  }

  // Mark-as-dead toggle for a row's job. Setting the job's saved value cancels
  // the pending toggle instead.
  setJoeStatus(id: number, value: ManualJoeStatus, savedValue: number): void {
    if (value === savedValue) {
      this.clearJoeStatus(id);
      return;
    }
    const next = new Map(this.joeToggles());
    next.set(id, value);
    this.joeToggles.set(next);
  }

  clearJoeStatus(id: number): void {
    const next = new Map(this.joeToggles());
    next.delete(id);
    this.joeToggles.set(next);
  }

  pendingJoeStatus(id: number): ManualJoeStatus | undefined {
    return this.joeToggles().get(id);
  }

  isDirty(id: number): boolean {
    return this.changes().has(id);
  }

  changedFields(id: number): TrackingChanges {
    return this.changes().get(id) ?? {};
  }

  // --- writes: only real differences go to the database ---

  // Row Save. Sends nothing when the row matches its snapshot.
  saveRow(id: number): Observable<void> {
    const sent = this.changedFields(id);
    if (Object.keys(sent).length === 0) return of(undefined);
    return this.api.rowSave(id, sent).pipe(
      tap((row) => this.applySaved(row, sent)),
      map(() => undefined),
    );
  }

  // Page-level Save All: every changed row, each with only its changed fields.
  // Emits how many rows were saved (0, with no request, when nothing changed).
  saveAll(): Observable<number> {
    const sent = new Map(this.changes());
    if (sent.size === 0) return of(0);
    const changes = [...sent].map(([id, changed_fields]) => ({ id, changed_fields }));
    return this.api.saveAll(changes).pipe(
      tap((rows) => rows.forEach((row) => this.applySaved(row, sent.get(row.id) ?? {}))),
      map((rows) => rows.length),
    );
  }

  // Edit page Save All: creates the application and adds its tracking row.
  saveApplication(params: SaveApplicationParams): Observable<TrackingEntry> {
    return this.applicationsApi.save(params).pipe(
      map(({ tracking }) => tracking),
      tap((entry) => {
        this.entries.update((list) => [entry, ...list]);
        this.saved.update((snapshot) => new Map(snapshot).set(entry.id, entry));
      }),
    );
  }

  // The server's row becomes the new snapshot. The working copy takes the
  // server's values too, except for fields edited again while the save was in
  // flight, which stay as pending changes.
  private applySaved(row: TrackingEntry, sent: TrackingChanges): void {
    const current = this.entries().find((entry) => entry.id === row.id);
    const before = this.saved().get(row.id);
    const merged: Record<string, unknown> = { ...row };
    if (current) {
      for (const field of EDITABLE_FIELDS) {
        const editedSince =
          field in sent
            ? !sameValue(current[field], sent[field])
            : !!before && !sameValue(current[field], before[field]);
        if (editedSince) merged[field] = current[field];
      }
    }

    this.entries.update((list) => list.map((entry) => (entry.id === row.id ? (merged as unknown as TrackingEntry) : entry)));
    this.saved.update((snapshot) => new Map(snapshot).set(row.id, row));

    const joeStatus = sent.joe_status;
    if (joeStatus !== undefined) {
      this.catalog.setJobJoeStatus(row.job_listing_id, joeStatus);
      if (this.joeToggles().get(row.id) === joeStatus) this.clearJoeStatus(row.id);
    }
  }
}
