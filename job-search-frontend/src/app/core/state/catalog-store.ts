import { Injectable, computed, inject, signal } from '@angular/core';
import { Observable, forkJoin, map, tap } from 'rxjs';
import { JobsApi } from '../api/jobs-api';
import { ResumesApi } from '../api/resumes-api';
import { CoverApi } from '../api/cover-api';
import { CoverLetter, DuplicateWarning, JobListing, Resume } from '../models';
import { describeError } from '../errors';

export type LoadStatus = 'idle' | 'loading' | 'loaded' | 'error';

// App-wide local copy of the saved jobs, resumes and cover letters, fetched
// once from the database on app load (PRD: local-state-first). Edit and
// Tracking read from here instead of fetching their own copies. Pages never
// call the API to write: they call this store, which sends the write and
// updates itself from the rows the server returns, so no page re-fetches.
@Injectable({ providedIn: 'root' })
export class CatalogStore {
  private jobsApi = inject(JobsApi);
  private resumesApi = inject(ResumesApi);
  private coverApi = inject(CoverApi);

  readonly jobs = signal<JobListing[]>([]);
  readonly resumes = signal<Resume[]>([]);
  readonly covers = signal<CoverLetter[]>([]);
  readonly status = signal<LoadStatus>('idle');
  readonly error = signal<string | null>(null);

  readonly jobsById = computed(() => new Map(this.jobs().map((j) => [j.id, j])));
  // Lets the Search page show which results are already saved.
  readonly savedJobUrls = computed(() => new Set(this.jobs().map((j) => j.url)));
  readonly resumesById = computed(() => new Map(this.resumes().map((r) => [r.id, r])));
  readonly coversById = computed(() => new Map(this.covers().map((c) => [c.id, c])));

  // Fetches all three lists once. Safe to call again: it does nothing while a
  // load is running or after one succeeded (use retry() after a failure).
  load(): void {
    if (this.status() === 'loading' || this.status() === 'loaded') return;
    this.status.set('loading');
    this.error.set(null);

    forkJoin({
      jobs: this.jobsApi.savedList(),
      resumes: this.resumesApi.savedList(),
      covers: this.coverApi.savedList(),
    }).subscribe({
      next: ({ jobs, resumes, covers }) => {
        this.jobs.set(markPassedExpiries(jobs));
        this.resumes.set(resumes);
        this.covers.set(covers);
        this.status.set('loaded');
      },
      error: (err) => {
        this.error.set(describeError(err, "Couldn't load your saved jobs, resumes and cover letters"));
        this.status.set('error');
      },
    });
  }

  retry(): void {
    if (this.status() === 'error') this.status.set('idle');
    this.load();
  }

  // --- writes: send to the database, then update local state from the reply ---

  // Search page Save All: the flagged results. Emits the duplicate warnings.
  saveJobs(listings: JobListing[]): Observable<DuplicateWarning[]> {
    return this.jobsApi.saveAll(listings).pipe(
      // Newly saved jobs go first: the list is newest first, like the API's.
      tap(({ saved }) => this.jobs.update((current) => [...saved, ...current])),
      map(({ warnings }) => warnings),
    );
  }

  // Tracking page refresh button: every saved listing comes back refreshed.
  // Emits how many were checked with JSearch.
  refreshListings(): Observable<number> {
    return this.jobsApi.refreshListings().pipe(
      tap(({ listings }) => this.jobs.set(markPassedExpiries(listings))),
      map(({ checked }) => checked),
    );
  }

  uploadResume(file: File, versionNote: string, extractedText: string): Observable<Resume> {
    return this.resumesApi
      .upload(file, versionNote, extractedText)
      .pipe(tap((resume) => this.resumes.update((current) => [resume, ...current])));
  }

  uploadCover(file: File, versionNote: string): Observable<CoverLetter> {
    return this.coverApi
      .upload(file, versionNote)
      .pipe(tap((cover) => this.covers.update((current) => [cover, ...current])));
  }

  // A mark-as-dead toggle that TrackingStore has just saved.
  setJobJoeStatus(jobId: number, joeStatus: number): void {
    this.jobs.update((jobs) => jobs.map((job) => (job.id === jobId ? { ...job, joe_status: joeStatus } : job)));
  }
}

// App-load Joe check (23 Oct rules): a green listing whose saved expiry date
// has passed shows amber. Done in the browser with no JSearch call, and only in
// local state: the stored joe_status changes only through a refresh or the
// manual toggle. Red (manually dead) listings are left alone.
function markPassedExpiries(jobs: JobListing[], now = Date.now()): JobListing[] {
  return jobs.map((job) => {
    const expires = job.job_offer_expires_at ? Date.parse(job.job_offer_expires_at) : NaN;
    return job.joe_status === 0 && expires < now ? { ...job, joe_status: 1 } : job;
  });
}
