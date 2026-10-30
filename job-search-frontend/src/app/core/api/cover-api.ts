import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CoverLetter } from '../models';

@Injectable({ providedIn: 'root' })
export class CoverApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  savedList(): Observable<CoverLetter[]> {
    return this.http.get<CoverLetter[]>(`${this.base}/cover/savedList`);
  }

  upload(file: File, versionNote: string): Observable<CoverLetter> {
    const form = new FormData();
    form.append('file', file, file.name);
    form.append('file_name', file.name);
    form.append('version_note', versionNote);
    return this.http.post<CoverLetter>(`${this.base}/cover/upload`, form);
  }
}
