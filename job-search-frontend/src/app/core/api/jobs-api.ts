import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { JobListing, RefreshListingsResponse, SaveAllResponse } from '../models';

export interface SearchParams {
  keyword: string;
  location?: string;
  remote?: boolean;
  jobType?: string;
  count?: number;
}

@Injectable({ providedIn: 'root' })
export class JobsApi {
  private http = inject(HttpClient);
  private base = environment.apiBaseUrl;

  search(params: SearchParams): Observable<JobListing[]> {
    let httpParams = new HttpParams().set('keyword', params.keyword);
    if (params.location) httpParams = httpParams.set('location', params.location);
    httpParams = httpParams.set('remote', String(params.remote ?? false));
    httpParams = httpParams.set('count', String(params.count ?? 10));
    if (params.jobType) httpParams = httpParams.set('job_type', params.jobType);

    return this.http.get<JobListing[]>(`${this.base}/jobs/search`, { params: httpParams });
  }

  savedList(): Observable<JobListing[]> {
    return this.http.get<JobListing[]>(`${this.base}/jobs/savedList`);
  }

  saveAll(listings: JobListing[]): Observable<SaveAllResponse> {
    return this.http.post<SaveAllResponse>(`${this.base}/jobs/saveAll`, { listings });
  }

  // Tracking page refresh button: asks JSearch about every saved job
  // (1 request per job checked).
  refreshListings(): Observable<RefreshListingsResponse> {
    return this.http.post<RefreshListingsResponse>(`${this.base}/jobs/refreshListings`, {});
  }
}
