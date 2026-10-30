import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SaveApplicationResponse } from '../models';

export interface SaveApplicationParams {
  resume_id: number;
  job_listing_id: number;
  cover_letter_id: number;
  match_score: number;
  resume_suggestions: string | null;
}

@Injectable({ providedIn: 'root' })
export class ApplicationsApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  save(params: SaveApplicationParams): Observable<SaveApplicationResponse> {
    return this.http.post<SaveApplicationResponse>(`${this.base}/applications/save`, params);
  }
}
