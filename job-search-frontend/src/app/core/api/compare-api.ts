import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ComparisonResult, JobListing } from '../models';

@Injectable({ providedIn: 'root' })
export class CompareApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  // Pure compute on the server: resume plain text (from pdf.js) + the full job record.
  compare(resumeText: string, jobListing: JobListing): Observable<ComparisonResult> {
    return this.http.post<ComparisonResult>(`${this.base}/compare`, {
      resume_text: resumeText,
      job_listing: jobListing,
    });
  }
}
