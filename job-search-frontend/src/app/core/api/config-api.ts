import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AppConfig } from '../models';

@Injectable({ providedIn: 'root' })
export class ConfigApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  load(): Observable<AppConfig> {
    return this.http.get<AppConfig>(`${this.base}/config`);
  }

  saveAll(fields: Partial<AppConfig>): Observable<AppConfig> {
    return this.http.patch<AppConfig>(`${this.base}/config/saveAll`, fields);
  }
}
