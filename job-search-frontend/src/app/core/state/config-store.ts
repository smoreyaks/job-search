import { Injectable, inject, signal } from '@angular/core';
import { Observable, of, tap } from 'rxjs';
import { ConfigApi } from '../api/config-api';
import { AppConfig } from '../models';

// The editable config fields, as the Config modal holds them while you type.
export type ConfigDraft = Pick<AppConfig, 'local_app_data' | 'delimiter' | 'compare_prompt'>;

const EDITABLE_FIELDS = ['local_app_data', 'delimiter', 'compare_prompt'] as const;

// Holds the single config row, loaded once on app init. It's also the saved
// snapshot: a save sends only the fields that differ from it, nothing at all
// when none do, and the returned row replaces it.
@Injectable({ providedIn: 'root' })
export class ConfigStore {
  private api = inject(ConfigApi);
  readonly config = signal<AppConfig | null>(null);

  load(): void {
    this.api.load().subscribe({ next: (config) => this.config.set(config) });
  }

  // Fields in the draft that differ from the saved config. A cleared field
  // ('') counts as the same as a saved null.
  changesFrom(draft: ConfigDraft): Partial<ConfigDraft> {
    const saved = this.config();
    if (!saved) return {};
    const changes: Partial<ConfigDraft> = {};
    for (const field of EDITABLE_FIELDS) {
      if ((draft[field] ?? '') !== (saved[field] ?? '')) {
        Object.assign(changes, { [field]: draft[field] });
      }
    }
    return changes;
  }

  save(draft: ConfigDraft): Observable<AppConfig | null> {
    const changes = this.changesFrom(draft);
    if (Object.keys(changes).length === 0) return of(this.config());
    return this.api.saveAll(changes).pipe(tap((config) => this.config.set(config)));
  }
}
