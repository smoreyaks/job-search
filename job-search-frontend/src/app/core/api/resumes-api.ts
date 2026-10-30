import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Resume } from '../models';

@Injectable({ providedIn: 'root' })
export class ResumesApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  savedList(): Observable<Resume[]> {
    return this.http.get<Resume[]>(`${this.base}/resumes/savedList`);
  }

  // The stored PDF itself, fetched on demand for the Edit page viewer.
  file(id: number): Observable<ArrayBuffer> {
    return this.http.get(this.fileUrl(id), { responseType: 'arraybuffer' });
  }

  fileUrl(id: number): string {
    return `${this.base}/resumes/${id}/file`;
  }

  upload(file: File, versionNote: string, extractedText: string): Observable<Resume> {
    const form = new FormData();
    form.append('file', file, file.name);
    form.append('file_name', file.name);
    form.append('version_note', versionNote);
    form.append('extracted_text', extractedText);
    return this.http.post<Resume>(`${this.base}/resume/upload`, form);
  }
}
