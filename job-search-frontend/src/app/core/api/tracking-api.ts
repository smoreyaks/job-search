import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { TrackingChanges, TrackingEntry } from '../models';

export interface TrackingChange {
  id: number;
  changed_fields: TrackingChanges;
}

@Injectable({ providedIn: 'root' })
export class TrackingApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  all(): Observable<TrackingEntry[]> {
    return this.http.get<TrackingEntry[]>(`${this.base}/tracking`);
  }

  rowSave(id: number, changedFields: TrackingChanges): Observable<TrackingEntry> {
    return this.http.patch<TrackingEntry>(`${this.base}/tracking/rowSave`, {
      id,
      changed_fields: changedFields,
    });
  }

  saveAll(changes: TrackingChange[]): Observable<TrackingEntry[]> {
    return this.http.patch<TrackingEntry[]>(`${this.base}/tracking/saveAll`, { changes });
  }
}
